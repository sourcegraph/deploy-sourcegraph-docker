#! /usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

yq w -i docker-compose.yaml services.*.cpus 1
yarn run prettier
