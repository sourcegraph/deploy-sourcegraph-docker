#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euo pipefail

box="$1"
exit_code=0
KEY_PATH="/tmp/e2e-builder.json"

pushd "test"

# Ask GCP to delete the VM, without waiting the 1-2 minutes the deletion takes
request_instance_deletion() (
	export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="$KEY_PATH"
	instance_name="$(cat ".vagrant/machines/${box}/google/id" 2>/dev/null)" &&
		instance_url="$(gcloud compute instances list --project=sourcegraph-ci --filter="name=${instance_name}" --format="value(selfLink)")" &&
		curl --fail --silent --show-error --output /dev/null --request DELETE \
			--header "Authorization: Bearer $(gcloud auth print-access-token)" "$instance_url"
)

# Fall back to a blocking destroy, so a failed deletion request cannot leak a VM
cleanup() {
	request_instance_deletion || vagrant destroy -f "$box"
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

echo --- ":vagrant: starting box $box"
vagrant up "$box" --provider=google || exit_code=$?

if [ "$exit_code" != 0 ]; then
	vagrant plugin install vagrant-scp
	vagrant scp "${box}:/deploy-sourcegraph-docker/*.log" ../
	exit $exit_code
fi
