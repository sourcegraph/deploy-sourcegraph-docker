#!/usr/bin/env bash
# Runs Sourcegraph in an Amp orb, as the `sourcegraph` service in .amp/services.yaml.
# Starts the Docker Compose deployment with Jaeger and an executor, creates the first site admin,
# then follows the logs until Amp stops the service.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
frontend_url="http://localhost:${PORT}"
admin_username='admin'
admin_email='admin@example.com'
secrets_directory="$HOME/.config/sourcegraph"

# Each orb makes its own secrets, so the repository holds none
make_secret() {
	if [[ ! -f "$secrets_directory/$1" ]]; then
		(umask 077 && mkdir -p "$secrets_directory" && openssl rand -hex 16 >"$secrets_directory/$1")
	fi
	cat "$secrets_directory/$1"
}
admin_password=$(make_secret admin-password)
executor_token=$(make_secret executor-token)

# Variables for .amp/docker-compose.override.yaml. A file keeps the token out of the sudo log
compose_variables="$secrets_directory/compose.env"
(umask 077 && printf 'PORT=%s\nEXECUTOR_TOKEN=%s\n' "$PORT" "$executor_token" >"$compose_variables")
compose=(sudo docker compose --env-file "$compose_variables"
	--file docker-compose/docker-compose.yaml
	--file docker-compose/jaeger/docker-compose.yaml
	--file docker-compose/executors/executor.docker-compose.yaml
	--file .amp/docker-compose.override.yaml)

# Start every service, then wait until the frontend is healthy.
# Waiting for every service fails, because searcher-0 reports unhealthy for a few seconds while it starts
"${compose[@]}" up --detach
"${compose[@]}" up --detach --wait sourcegraph-frontend-0

# Sourcegraph refuses this request once it has a user, so only the first start configures the site below
site_init_status=$(curl --silent --output /dev/null --write-out '%{http_code}' --request POST "$frontend_url/-/site-init" \
	--header 'Content-Type: application/json' \
	--data "{\"email\":\"$admin_email\",\"username\":\"$admin_username\",\"password\":\"$admin_password\"}")

# Stop here if the admin cannot sign in. The session cookie also authorizes the GraphQL requests below
cookie_jar=$(mktemp)
portal_name=sourcegraph-admin
trap 'rm -f "$cookie_jar" ".amp/portals/$portal_name.json"' EXIT
# When Amp stops the service, wait for Docker Compose to stop the containers, then remove the files above
trap exit TERM
curl --silent --fail --output /dev/null --cookie-jar "$cookie_jar" --request POST "$frontend_url/-/sign-in" \
	--header 'Content-Type: application/json' \
	--data "{\"email\":\"$admin_email\",\"password\":\"$admin_password\"}"

if [[ "$site_init_status" == 200 ]]; then
	# Prints the response, and fails if it has errors
	graphql() {
		curl --silent --fail --cookie "$cookie_jar" --header 'Content-Type: application/json' --data "$1" "$frontend_url/.api/graphql" |
			jq --exit-status 'select(.errors == null)'
	}
	configuration_id=$(graphql '{"query":"{ site { configuration { id } } }"}' | jq '.data.site.configuration.id')
	# Lets the executor connect, and gives Sourcegraph its portal URL
	site_configuration=$(jq --null-input --arg token "$executor_token" --arg url "$PUBLIC_URL" \
		'{"externalURL": $url, "auth.providers": [{"type": "builtin"}], "executors.accessToken": $token}')
	graphql "$(jq --null-input --argjson id "$configuration_id" --arg input "$site_configuration" \
		'{query: "mutation($id: Int!, $input: String!) { updateSiteConfiguration(lastID: $id, input: $input) }",
		variables: {id: $id, input: $input}}')" >/dev/null
fi

# Shows the sign-in in the Portal tab, as a note next to the Sourcegraph link, until the service stops
amp orb portal "$PORT" --name "$portal_name" --title Sourcegraph \
	--description "Sign in as $admin_username with the password $admin_password"

# Stay in the foreground. Stopping the service stops the containers
"${compose[@]}" up
