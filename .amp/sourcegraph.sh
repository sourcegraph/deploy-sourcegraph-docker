#!/usr/bin/env bash
# Runs Sourcegraph in an Amp orb, as the `sourcegraph` service in .amp/services.yaml.
# Starts the Docker Compose deployment with Jaeger and an executor, creates the first site admin,
# then follows the logs until Amp stops the service.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
frontend_url="http://localhost:${PORT}"
admin_username='admin'
admin_email='admin@example.com'
# The same in every orb, so nobody has to look it up
admin_password='Sourcegraph123'
secrets_directory="$HOME/.config/sourcegraph"

# Each orb makes its own executor token
executor_token_file="$secrets_directory/executor-token"
if [[ ! -f "$executor_token_file" ]]; then
	(umask 077 && mkdir -p "$secrets_directory" && openssl rand -hex 16 >"$executor_token_file")
fi
executor_token=$(<"$executor_token_file")

# Variables for .amp/docker-compose.override.yaml. A file keeps the token out of the sudo log
compose_variables="$secrets_directory/compose.env"
(umask 077 && printf 'PORT=%s\nEXECUTOR_TOKEN=%s\n' "$PORT" "$executor_token" >"$compose_variables")
compose=(sudo docker compose --env-file "$compose_variables"
	--file docker-compose/docker-compose.yaml
	--file docker-compose/jaeger/docker-compose.yaml
	--file docker-compose/executors/executor.docker-compose.yaml
	--file .amp/docker-compose.override.yaml)

# Start every service, then wait until the frontend is healthy.
# Waiting for every service fails, because searcher-0 reports unhealthy for a few seconds while it starts.
# The first start pulls the images, and Docker Hub times out now and then
"${compose[@]}" up --detach || { sleep 10 && "${compose[@]}" up --detach; }
"${compose[@]}" up --detach --wait sourcegraph-frontend-0

# Sourcegraph refuses this request once it has a user, so a restart keeps the first admin
curl --silent --output /dev/null --request POST "$frontend_url/-/site-init" \
	--header 'Content-Type: application/json' \
	--data "{\"email\":\"$admin_email\",\"username\":\"$admin_username\",\"password\":\"$admin_password\"}"

# Stop here if the admin cannot sign in. The session cookie also authorizes the GraphQL requests below
cookie_jar=$(mktemp)
portal_name=sourcegraph-admin
trap 'rm -f "$cookie_jar" ".amp/portals/$portal_name.json"' EXIT
# When Amp stops the service, wait for Docker Compose to stop the containers, then remove the files above
trap exit TERM
curl --silent --fail --output /dev/null --cookie-jar "$cookie_jar" --request POST "$frontend_url/-/sign-in" \
	--header 'Content-Type: application/json' \
	--data "{\"email\":\"$admin_email\",\"password\":\"$admin_password\"}"

# Prints the response, and fails if it has errors
graphql() {
	curl --silent --fail --cookie "$cookie_jar" --header 'Content-Type: application/json' --data "$1" "$frontend_url/.api/graphql" |
		jq --exit-status 'select(.errors == null)'
}
# The site configuration is JSON with comments, so drop whole-line comments and trailing commas to read it
site=$(graphql '{"query":"{ site { configuration { id effectiveContents } } }"}' | jq '.data.site.configuration |
	{id, contents: (.effectiveContents | gsub("(?m)^\\s*//.*$"; "") | gsub(",(?=\\s*[]}])"; "") | fromjson? // null)}')
# Configure the site only while it has no executor token, so restarts keep later changes.
# Leave it alone if it does not parse
if jq --exit-status '.contents != null and (.contents | has("executors.accessToken") | not)' <<<"$site" >/dev/null; then
	# Gives Sourcegraph its portal URL, lets the executor and the containers it starts connect,
	# lets code intelligence jobs be queued, and sends traces to Jaeger
	site_configuration=$(jq --arg url "${PUBLIC_URL%/}" --arg token "$executor_token" '.contents + {
		"externalURL": $url,
		"executors.accessToken": $token,
		"executors.frontendURL": "http://host.docker.internal",
		"codeIntelAutoIndexing.enabled": true,
		"observability.tracing": {"urlTemplate": "{{ .ExternalURL }}/-/debug/jaeger/trace/{{ .TraceID }}"}
	}' <<<"$site")
	graphql "$(jq --arg input "$site_configuration" \
		'{query: "mutation($id: Int!, $input: String!) { updateSiteConfiguration(lastID: $id, input: $input) }",
		variables: {id, input: $input}}' <<<"$site")" >/dev/null
fi

# Shows the sign-in in the Portal tab, as a note next to the Sourcegraph link, until the service stops
amp orb portal "$PORT" --name "$portal_name" --title Sourcegraph \
	--description "Sign in as $admin_username with the password $admin_password"

# Free the disk that images and volumes of earlier versions hold.
# Every container of this deployment exists by now, so Docker keeps their images and volumes
sudo docker image prune --all --force | tail -n 1
sudo docker volume prune --all --force | tail -n 1

# Stay in the foreground. Stopping the service stops the containers
"${compose[@]}" up
