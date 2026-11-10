#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euo pipefail

box="$1"

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

for attempt in 1 2; do
	echo --- ":vagrant: starting box $box, attempt $attempt of 2"
	exit_code=0
	vagrant up "$box" --provider=google || exit_code=$?
	[ "$exit_code" = 0 ] && break

	# A VM which stopped answering SSH did not fail the test, and has no logs to copy,
	# so run the test again on a new VM
	if vagrant ssh "$box" --no-tty --command true -- -o ConnectTimeout=15; then
		vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
		break
	fi
	echo "Lost the SSH connection to $box"
	vagrant destroy -f "$box"
done

exit "$exit_code"
