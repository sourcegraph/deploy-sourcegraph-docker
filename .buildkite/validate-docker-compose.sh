#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

docker-compose -f docker-compose/docker-compose.yaml config -q
