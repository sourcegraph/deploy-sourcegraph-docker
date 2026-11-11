#!/usr/bin/env bash
# Runs Sourcegraph in an Amp orb, as the `sourcegraph` service in .amp/services.yaml.
# Starts the Docker Compose deployment, creates the first site admin,
# then follows the logs until Amp stops the service.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
compose=(sudo docker compose --file docker-compose/docker-compose.yaml)
frontend_url="http://localhost:${PORT}"
admin_username='admin'
admin_email='admin@example.com'
password_file="$HOME/.config/sourcegraph/admin-password"

# Start every service, then wait until the frontend is healthy
"${compose[@]}" up --detach
"${compose[@]}" up --detach --wait sourcegraph-frontend-0

# Each orb makes its own password, so the repository holds none
if [[ ! -f "$password_file" ]]; then
	mkdir -p "$(dirname "$password_file")"
	(umask 077 && openssl rand -hex 16 >"$password_file")
fi
admin_password=$(<"$password_file")

# Sourcegraph refuses this request once it has a user, so a restart keeps the first admin
curl --silent --output /dev/null --request POST "$frontend_url/-/site-init" \
	--header 'Content-Type: application/json' \
	--data "{\"email\":\"$admin_email\",\"username\":\"$admin_username\",\"password\":\"$admin_password\"}"

# Stop here if the admin cannot sign in
curl --silent --fail --output /dev/null --request POST "$frontend_url/-/sign-in" \
	--header 'Content-Type: application/json' \
	--data "{\"email\":\"$admin_email\",\"password\":\"$admin_password\"}"

echo "Sourcegraph is ready at ${PUBLIC_URL}"
echo "Sign in as $admin_username with the password in $password_file"

# Stay in the foreground. Stopping the service stops the containers
exec "${compose[@]}" up
