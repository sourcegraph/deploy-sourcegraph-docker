#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euo pipefail

box="$1"
exit_code=0
KEY_PATH="/tmp/e2e-builder.json"

pushd "test"

# Ask GCP to delete the VMs matching a filter, without waiting the 1-2 minutes a deletion takes
request_instance_deletion() (
	export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="$KEY_PATH"
	gcloud compute instances list --project=sourcegraph-ci --filter="$1" --format="value(selfLink)" | tee /dev/stderr |
		xargs --no-run-if-empty --max-args=1 curl --fail --silent --show-error --output /dev/null \
			--request DELETE --header "Authorization: Bearer $(gcloud auth print-access-token)"
)

# Find this job's VM by its label, because Vagrant only knows about the VM once GCP has finished creating it.
# Fall back to a blocking destroy, so a failed deletion request cannot leak a VM
cleanup() {
	request_instance_deletion "labels.buildkite-job-id=${BUILDKITE_JOB_ID}" || vagrant destroy -f "$box"
}

echo --- ":vagrant: installing plugins"
vagrant --version
# Agents on the same host share ~/.vagrant.d, so only the first job on a new host installs
[[ "$(vagrant plugin list)" == *"vagrant-google (2.7.0"* ]] || vagrant plugin install vagrant-google --plugin-version '2.7.0'

trap cleanup EXIT

echo --- ":lock: builder account key"
if [ ! -f ${KEY_PATH} ]; then
  gcloud secrets versions access latest --secret=e2e-builder-sa-key --quiet --project=sourcegraph-ci > "${KEY_PATH}"
fi
export GOOGLE_JSON_KEY_LOCATION="${KEY_PATH}"
export DOCKER_USERNAME=sourcegraph
export DOCKER_PASSWORD="$(gcloud secrets versions access latest --secret=DOCKER_PASSWORD_BUILDKITE_AGENT --quiet --project=sourcegraph-ci)"

echo --- ":wastebasket: deleting VMs left behind by jobs which died before their cleanup"
# The smoke test step times out after 30 minutes, so a VM older than an hour has no job
request_instance_deletion "labels.buildkite-job-id:* AND creationTimestamp<-PT1H" || echo "Could not delete stale VMs"

echo --- ":vagrant: starting box $box"
vagrant up "$box" --provider=google || exit_code=$?

if [ "$exit_code" != 0 ]; then
	vagrant plugin install vagrant-scp
	vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
	exit $exit_code
fi
