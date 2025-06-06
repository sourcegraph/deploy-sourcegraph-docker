#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euo pipefail

box="$1"
exit_code=0

pushd "test"

cleanup() {
	vagrant destroy -f "$box"
}

echo --- ":vagrant: installing plugins"
plugins=(vagrant-google vagrant-env vagrant-scp)
for i in "${plugins[@]}"; do
  vagrant plugin list --no-tty
	if ! vagrant plugin list --no-tty | grep "$i"; then
		vagrant plugin install "$i"
	fi
done

trap cleanup EXIT

echo --- ":bug: fixing dotenv"
echo "see Fix plugin: https://github.com/hashicorp/vagrant/issues/13550"
sed -i -e 's/exists?/exist?/g' /var/lib/buildkite-agent/.vagrant.d/gems/3.3.8/gems/dotenv-0.11.1/lib/dotenv.rb

echo --- ":vagrant: starting box $box"
vagrant up "$box" --provider=google || exit_code=$?

if [ "$exit_code" != 0 ]; then
	vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
	exit $exit_code
fi
