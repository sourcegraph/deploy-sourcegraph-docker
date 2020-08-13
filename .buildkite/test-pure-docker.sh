#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

cd test/pure-docker/
vagrant up
./smoke-test.sh
vagrant destroy pure-docker-test
