#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euxo pipefail

box="$1"
exit_code=0

pushd "test"

cleanup() {
	vagrant destroy -f "$box"
}

plugins=(vagrant-google vagrant-env vagrant-scp)
for i in "${plugins[@]}"; do
	if ! vagrant plugin list --no-tty | grep "$i"; then
		vagrant plugin install "$i"
	fi
done

trap cleanup EXIT
vagrant up "$box" --provider=google || exit_code=$?

if [ "$exit_code" != 0 ]; then
	vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
	exit $exit_code
fi
