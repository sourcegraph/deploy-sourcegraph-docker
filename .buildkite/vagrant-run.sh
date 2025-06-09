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
vagrant --version
vagrant plugin install vagrant-google --plugin-version '2.7.0'
vagrant plugin install vagrant-env
vagrant plugin install vagrant-scp

trap cleanup EXIT

# echo --- ":bug: fixing dotenv"
# echo "see fix: https://github.com/hashicorp/vagrant/issues/13550"
# sed -i -e 's/exists?/exist?/g' /var/lib/buildkite-agent/.vagrant.d/gems/3.3.8/gems/dotenv-0.11.1/lib/dotenv.rb

echo --- ":lock: builder account key"
KEY_PATH="/tmp/e2e-builder.json"
if [ ! -f ${KEY_PATH} ]; then
  gcloud secrets versions access latest --secret=e2e-builder-sa-key --quiet --project=sourcegraph-ci > "${KEY_PATH}"
fi
export GOOGLE_JSON_KEY_LOCATION="${KEY_PATH}"

echo --- ":vagrant: starting box $box"
vagrant up "$box" --provider=google || exit_code=$?

if [ "$exit_code" != 0 ]; then
	vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
	exit $exit_code
fi
