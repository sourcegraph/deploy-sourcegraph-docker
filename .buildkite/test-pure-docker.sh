#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

cd test/pure-docker/
vagrant destroy -f pure-docker-test
vagrant up
vagrant destroy -f pure-docker-test
