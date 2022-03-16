#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

which docker-compose
#cd docker-compose
#docker-compose -f docker-compose.yaml config -q
