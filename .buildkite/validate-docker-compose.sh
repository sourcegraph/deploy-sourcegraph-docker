#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../docker-compose"
set -euxo pipefail

docker compose version

# Every Compose file, combined the way its docs say to run it
docker compose --file docker-compose.yaml config --quiet
docker compose --file db-only-migrate.docker-compose.yaml config --quiet
docker compose --file docker-compose.yaml --file jaeger/docker-compose.yaml config --quiet
docker compose --file docker-compose.yaml --file jaeger/docker-compose.yaml --file dev/docker-compose.yaml config --quiet
docker compose --file docker-compose.yaml --file executors/executor.docker-compose.yaml config --quiet
docker compose --file executors/executor.docker-compose.yaml config --quiet
for override in examples/*/docker-compose.override.yaml; do
	docker compose --file docker-compose.yaml --file "$override" config --quiet
done
