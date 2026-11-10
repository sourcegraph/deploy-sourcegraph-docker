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

ssh_answers() {
	vagrant ssh "$box" --no-tty --command true -- -o ConnectTimeout=15
}

echo --- ":vagrant: starting box $box"
vagrant up "$box" --provider=google || exit_code=$?

# vagrant up gives up when the VM stops answering SSH, which is not a test failure.
# Retry the SSH connection to the same VM, then sync the repo and run the test on it
if [ "$exit_code" != 0 ] && ! ssh_answers; then
	for attempt in {1..10}; do
		echo "$box does not answer SSH, retry $attempt of 10 in 15 seconds"
		sleep 15
		if ssh_answers; then
			exit_code=0
			vagrant provision "$box" || exit_code=$?
			break
		fi
	done
fi

if [ "$exit_code" != 0 ]; then
	vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
	exit $exit_code
fi
