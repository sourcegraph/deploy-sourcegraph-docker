#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

sed -i 's/--cpu/#--cpu/g' deploy-.sh
cd test/pure-docker/

if ! vagrant plugin list --no-tty | grep vagrant-google; then

	vagrant plugin install vagrant-google

fi

time vagrant up pure-docker-test-local --provider=virtualbox
vagrant destroy -f pure-docker-test-local
