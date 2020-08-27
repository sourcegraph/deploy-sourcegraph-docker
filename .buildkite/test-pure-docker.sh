#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

cd test/pure-docker/

if ! vagrant plugin list --no-tty | grep vagrant-google; then

	vagrant plugin install vagrant-google

fi

vagrant up pure-docker-test --provider=google
vagrant destroy -f pure-docker-test
