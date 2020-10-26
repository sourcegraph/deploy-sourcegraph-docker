#! /usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -exo pipefail

yq w -i docker-compose.yaml services.*.cpus ${1:-1}
yarn run prettier
