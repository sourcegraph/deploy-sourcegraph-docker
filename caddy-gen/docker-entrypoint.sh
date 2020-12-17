#!/bin/sh

set -eu

# Create initial configuration:
docker-gen /etc/docker-gen/template/Caddyfile.tmpl /etc/caddy/Caddyfile

# Execute passed command:
exec "$@"
