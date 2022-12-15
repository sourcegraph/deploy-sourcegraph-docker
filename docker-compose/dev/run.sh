#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
set -euxo pipefail

docker-compose \
    -f docker-compose/docker-compose.yaml \
    -f docker-compose/jaeger/docker-compose.yaml \
    -f docker-compose/dev/docker-compose.yaml \
    "$@"
