#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euo pipefail

box="$1"
exit_code=0
KEY_PATH="$(mktemp)"

pushd "test"

# Vagrant creates a disk, then a VM, both with this name, and only knows about them once GCP has finished
# creating the VM. Naming them after the job lets the cleanup find them if the job is cancelled before that
instance_name_prefix="${box}-job-"
export VAGRANT_INSTANCE_NAME="${instance_name_prefix}${BUILDKITE_JOB_ID}"

# Ask GCP to delete the VMs matching a filter, and the matching disks which no VM uses,
# without waiting the 1-2 minutes a deletion takes. GCP deletes a VM's disk with the VM
request_deletion() (
	export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="$KEY_PATH"
	{
		gcloud compute instances list --project=sourcegraph-ci --filter="$1" --format="value(selfLink)" &&
			gcloud compute disks list --project=sourcegraph-ci --filter="($1) AND -users:*" --format="value(selfLink)"
	} | tee /dev/stderr |
		xargs --no-run-if-empty --max-args=1 curl --fail --silent --show-error --output /dev/null \
			--request DELETE --header "Authorization: Bearer $(gcloud auth print-access-token)"
)

# Fall back to a blocking destroy, so a failed deletion request cannot leak a VM
cleanup() {
	deletion_status=0
	request_deletion "name=${VAGRANT_INSTANCE_NAME}" || vagrant destroy -f "$box" || deletion_status=$?
	rm -f "$KEY_PATH"
	return "$deletion_status"
}

echo --- ":vagrant: installing plugins"
vagrant --version
# Agents on the same host share ~/.vagrant.d, so only the first job on a new host installs
[[ "$(vagrant plugin list)" == *"vagrant-google (2.7.0"* ]] || vagrant plugin install vagrant-google --plugin-version '2.7.0'

trap cleanup EXIT

echo --- ":lock: builder account key"
gcloud secrets versions access latest --secret=e2e-builder-sa-key --quiet --project=sourcegraph-ci > "${KEY_PATH}"
export GOOGLE_JSON_KEY_LOCATION="${KEY_PATH}"
DOCKER_PASSWORD="$(gcloud secrets versions access latest --secret=DOCKER_PASSWORD_BUILDKITE_AGENT --quiet --project=sourcegraph-ci)"
export DOCKER_USERNAME=sourcegraph DOCKER_PASSWORD

echo --- ":wastebasket: deleting VMs and disks left behind by jobs which died before their cleanup"
# The smoke test step times out after 30 minutes, so a VM or disk older than an hour has no job
request_deletion "name~^${instance_name_prefix} AND creationTimestamp<-PT1H" || echo "Could not delete stale VMs and disks"

echo --- ":vagrant: starting box $box"
vagrant up "$box" --provider=google || exit_code=$?

if [ "$exit_code" != 0 ]; then
	vagrant plugin install vagrant-scp
	vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
	exit $exit_code
fi
