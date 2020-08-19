#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

cd test/pure-docker/
vagrant plugin install vagrant-google
vagrant up pure-docker-test-local
vagrant destroy -f
