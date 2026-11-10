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

echo --- ":lock: builder account key"
KEY_PATH="/tmp/e2e-builder.json"
if [ ! -f ${KEY_PATH} ]; then
  gcloud secrets versions access latest --secret=e2e-builder-sa-key --quiet --project=sourcegraph-ci > "${KEY_PATH}"
fi
export GOOGLE_JSON_KEY_LOCATION="${KEY_PATH}"
export DOCKER_USERNAME=sourcegraph
export DOCKER_PASSWORD="$(gcloud secrets versions access latest --secret=DOCKER_PASSWORD_BUILDKITE_AGENT --quiet --project=sourcegraph-ci)"

echo --- ":vagrant: starting box $box"
vagrant up "$box" --provider=google || exit_code=$?

if [ "$exit_code" != 0 ]; then
	# A VM which stopped answering SSH did not fail the test, and has no logs to copy
	if ! vagrant ssh "$box" --no-tty --command true -- -o ConnectTimeout=15; then
		echo "Lost the SSH connection to $box, so the test has no result. pipeline.yaml retries exit status 75 on a new VM"
		exit 75
	fi
	vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
	exit $exit_code
fi
