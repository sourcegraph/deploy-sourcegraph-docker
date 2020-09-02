#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

box=$1

cd test/

if ! vagrant plugin list --no-tty | grep vagrant-google; then
	vagrant plugin install vagrant-google
fi

vagrant up $box --provider=google
vagrant destroy -f $box
