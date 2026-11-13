#!/usr/bin/env bash
# Runs Sourcegraph in an Amp orb, as the `sourcegraph` service in .amp/services.yaml.
# Starts the Docker Compose deployment with Jaeger and an executor, creates the first site admin,
# then follows the logs until Amp stops the service.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
frontend_url="http://localhost:${PORT}"
portal_url=${PUBLIC_URL%/}
# The first site admin, from the Amp project's environment variables, so it is the same in every orb
admin_username=${SOURCEGRAPH_ADMIN_USERNAME:?"Set it in the Amp project's environment variables"}
admin_email=${SOURCEGRAPH_ADMIN_EMAIL:?"Set it in the Amp project's environment variables"}
admin_password=${SOURCEGRAPH_ADMIN_PASSWORD:?"Set it in the Amp project's environment variables"}
secrets_directory="$HOME/.config/sourcegraph"

# Each orb makes its own executor token
executor_token_file="$secrets_directory/executor-token"
if [[ ! -s "$executor_token_file" ]]; then
	(umask 077 && mkdir -p "$secrets_directory" && openssl rand -hex 16 >"$executor_token_file")
fi
executor_token=$(<"$executor_token_file")
# The token last written to the site configuration, which shows it only as REDACTED
configured_token_file="$secrets_directory/configured-executor-token"

# Caddy serves this file at /-/amp-ready, the health check in .amp/services.yaml, so Amp reports the service
# ready only once the site admin exists and the site is configured
ready_directory="$secrets_directory/ready"
mkdir -p "$ready_directory"
rm -f "$ready_directory/ready"

# Variables for .amp/docker-compose.override.yaml. A file keeps the token out of the sudo log
compose_variables="$secrets_directory/compose.env"
(umask 077 && printf 'PORT=%s\nEXECUTOR_TOKEN=%s\nREADY_DIRECTORY=%s\n' "$PORT" "$executor_token" "$ready_directory" \
	>"$compose_variables")
compose=(sudo docker compose --env-file "$compose_variables"
	--file docker-compose/docker-compose.yaml
	--file docker-compose/jaeger/docker-compose.yaml
	--file docker-compose/executors/executor.docker-compose.yaml)
# Naming files turns off Compose's own pick-up of the override file customers keep their changes in
if [[ -f docker-compose/docker-compose.override.yaml ]]; then
	compose+=(--file docker-compose/docker-compose.override.yaml)
fi
compose+=(--file .amp/docker-compose.override.yaml)

# When Amp stops the service, or a step fails, stop the containers and remove these files
cookie_jar=$(mktemp)
portal_name=sourcegraph-admin
trap 'rm -f "$ready_directory/ready"; "${compose[@]}" stop; rm -f "$cookie_jar" ".amp/portals/$portal_name.json"' EXIT
trap exit TERM

# Start every service, then wait until the frontend is healthy.
# Waiting for every service fails, because searcher-0 reports unhealthy for a few seconds while it starts.
# The first start pulls the images, and Docker Hub times out now and then.
# --remove-orphans removes the containers of services the Compose files no longer have, such as after a rename
"${compose[@]}" up --remove-orphans --detach || { sleep 10 && "${compose[@]}" up --remove-orphans --detach; }
"${compose[@]}" up --remove-orphans --detach --wait sourcegraph-frontend-0

# Posts JSON, keeps the session cookie, and prints Sourcegraph's reason when it refuses
post() {
	curl --silent --show-error --fail-with-body --cookie-jar "$cookie_jar" \
		--header 'Content-Type: application/json' --data "$2" "$frontend_url$1"
}
credentials=$(jq --null-input --arg email "$admin_email" --arg username "$admin_username" \
	--arg password "$admin_password" '{$email, $username, $password}')
# Sign in, or create the first site admin, which also signs in. The session authorizes the GraphQL requests below
if ! sign_in_error=$(post /-/sign-in "$credentials" 2>&1) &&
	! site_init_error=$(post /-/site-init "$credentials" 2>&1); then
	echo "Could not sign in as $admin_username: ${sign_in_error//$'\n'/ }" >&2
	echo "Could not create that site admin: ${site_init_error//$'\n'/ }" >&2
	echo "Sourcegraph creates only the first site admin, so after changing the SOURCEGRAPH_ADMIN_* variables," \
		"change that user to match" >&2
	exit 1
fi

# Prints the response, and fails with its errors
graphql() {
	curl --silent --show-error --fail-with-body --cookie "$cookie_jar" --header 'Content-Type: application/json' \
		--data "$1" "$frontend_url/.api/graphql" |
		jq --exit-status 'if .errors then "GraphQL errors: \(.errors)\n" | halt_error else . end'
}
# The site configuration is JSON with comments, so drop whole-line comments and trailing commas to read it
site=$(graphql '{"query":"{ site { configuration { id effectiveContents } } }"}' | jq '.data.site.configuration |
	{id, contents: (.effectiveContents | gsub("(?m)^\\s*//.*$"; "") | gsub(",(?=\\s*[]}])"; "") | fromjson? // null)}')
# Configure the site when it has no executor token, has an older one, or has another portal URL.
# Otherwise leave it alone, so restarts keep later changes and its comments
if jq --exit-status '.contents == null' <<<"$site" >/dev/null; then
	echo 'Could not parse the site configuration, so left it alone' >&2
elif [[ "$executor_token" != "$(cat "$configured_token_file" 2>/dev/null)" ]] ||
	jq --exit-status --arg url "$portal_url" \
		'.contents | (has("executors.accessToken") | not) or .externalURL != $url' <<<"$site" >/dev/null; then
	# Gives Sourcegraph its portal URL, lets the executor and the containers it starts connect,
	# lets code intelligence jobs be queued, and sends traces to Jaeger
	site_configuration=$(jq --arg url "$portal_url" --arg token "$executor_token" '.contents + {
		"externalURL": $url,
		"executors.accessToken": $token,
		"executors.frontendURL": "http://host.docker.internal",
		"codeIntelAutoIndexing.enabled": true,
		"observability.tracing": {"urlTemplate": "{{ .ExternalURL }}/-/debug/jaeger/trace/{{ .TraceID }}"}
	}' <<<"$site")
	graphql "$(jq --arg input "$site_configuration" \
		'{query: "mutation($id: Int!, $input: String!) { updateSiteConfiguration(lastID: $id, input: $input) }",
		variables: {id, input: $input}}' <<<"$site")" >/dev/null
	(umask 077 && cp "$executor_token_file" "$configured_token_file")
fi

# Shows the sign-in in the Portal tab, as a note next to the Sourcegraph link, until the service stops
amp orb portal "$PORT" --name "$portal_name" --title Sourcegraph \
	--description "Sign in as $admin_username with the password $admin_password"
touch "$ready_directory/ready"

# Free the disk that images of earlier versions hold, once the deployment's images change.
# Every container of this deployment exists by now, so Docker keeps their images.
# Not on every start, because that also removes the images of executor jobs, which then pull again
images_file="$secrets_directory/images"
images=$("${compose[@]}" config --images | sort)
if [[ "$images" != "$(cat "$images_file" 2>/dev/null)" ]]; then
	sudo docker image prune --all --force | tail -n 1
	echo "$images" >"$images_file"
fi

# Stay in the foreground. Stopping the service stops the containers
"${compose[@]}" up --remove-orphans
