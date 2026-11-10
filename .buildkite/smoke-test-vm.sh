#!/usr/bin/env bash

# Runs test/smoke-test.sh on a new GCP VM booted from $IMAGE, then deletes the VM

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euo pipefail

KEY_PATH="$(mktemp)"
project="sourcegraph-ci"
zone="us-central1-f"

# GCP creates a disk, then a VM, both with this name. Naming them after the job
# lets the cleanup find them if the job is cancelled before the VM exists
instance_name_prefix="docker-test-job-"
instance_name="${instance_name_prefix}${BUILDKITE_JOB_ID}"

# Ask GCP to delete the VMs matching a filter, and the matching disks which no VM uses,
# without waiting the 1-2 minutes a deletion takes. GCP deletes a VM's disk with the VM
request_deletion() {
	{
		gcloud compute instances list --project="$project" --filter="$1" --format="value(selfLink)" &&
			gcloud compute disks list --project="$project" --filter="($1) AND -users:*" --format="value(selfLink)"
	} | tee /dev/stderr |
		xargs --no-run-if-empty --max-args=1 curl --fail --silent --show-error --output /dev/null \
			--request DELETE --header "Authorization: Bearer $(gcloud auth print-access-token)"
}

# Fall back to a blocking delete, so a failed deletion request cannot leak a VM
cleanup() {
	deletion_status=0
	request_deletion "name=${instance_name}" ||
		gcloud compute instances delete "$instance_name" --project="$project" --zone="$zone" --quiet ||
		deletion_status=$?
	rm -rf "$KEY_PATH" "$ssh_directory"
	return "$deletion_status"
}

# A key for this job only, which the VM's guest agent authorizes for the buildkite user
ssh_directory="$(mktemp -d)"
ssh-keygen -q -t ed25519 -N "" -C buildkite -f "$ssh_directory/key"
ssh_options=(-i "$ssh_directory/key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5)

trap cleanup EXIT

echo --- ":lock: builder account key"
gcloud secrets versions access latest --secret=e2e-builder-sa-key --quiet --project=sourcegraph-ci >"${KEY_PATH}"
DOCKER_PASSWORD="$(gcloud secrets versions access latest --secret=DOCKER_PASSWORD_BUILDKITE_AGENT --quiet --project=sourcegraph-ci)"
export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="$KEY_PATH"

echo --- ":wastebasket: deleting VMs and disks left behind by jobs which died before their cleanup"
# The smoke test step times out after 30 minutes, so a VM or disk older than an hour has no job
request_deletion "name~^${instance_name_prefix} AND creationTimestamp<-PT1H" || echo "Could not delete stale VMs and disks"

echo --- ":gcloud: starting VM $instance_name"
ip_address="$(gcloud compute instances create "$instance_name" \
	--project="$project" --zone="$zone" \
	--image="$IMAGE" --image-project="$project" \
	--machine-type=custom-16-20480 \
	--boot-disk-size=20GB --boot-disk-type=pd-standard \
	--network=default --no-address \
	--service-account="e2e-builder@${project}.iam.gserviceaccount.com" --scopes=compute-rw,storage-ro \
	--labels=team=dev-infra,type=smoke-test \
	--metadata="ssh-keys=buildkite:$(cat "$ssh_directory/key.pub")" \
	--format="value(networkInterfaces[0].networkIP)")"
remote="buildkite@${ip_address}"

echo --- ":ssh: waiting for the VM to accept SSH"
deadline=$((SECONDS + 600))
until ssh "${ssh_options[@]}" "$remote" true; do
	if ((SECONDS > deadline)); then
		echo "The VM did not accept SSH within 10 minutes"
		exit 1
	fi
	sleep 2
done

echo --- ":package: copying the repository to the VM"
tar --create --gzip --exclude=.git --exclude=node_modules . |
	ssh "${ssh_options[@]}" "$remote" "sudo mkdir /deploy-sourcegraph-docker && sudo tar --extract --gzip --directory=/deploy-sourcegraph-docker"

echo --- ":docker: running the smoke tests"
# Runs as root on the VM. The Docker Hub password comes over stdin, so it does not show in the VM's process list
remote_script='
set -euo pipefail
read -r DOCKER_PASSWORD
export DOCKER_USERNAME=sourcegraph DOCKER_PASSWORD
/deploy-sourcegraph-docker/test/smoke-test.sh
# The VM image has no jq. Skip /etc/apt/sources.list.d: the image lacks the key for its Chrome repository, so a full update fails
apt-get update --quiet --option Dir::Etc::sourceparts=- && apt-get install --quiet --yes jq
/deploy-sourcegraph-docker/test/executor-smoke-test.sh
'
exit_code=0
# shellcheck disable=SC2029 # remote_script is quoted here, to run on the VM
ssh "${ssh_options[@]}" "$remote" "sudo bash -c $(printf %q "$remote_script")" <<<"$DOCKER_PASSWORD" || exit_code=$?

if [ "$exit_code" != 0 ]; then
	# Copy back the container logs the smoke test wrote, for the step's artifacts
	ssh "${ssh_options[@]}" "$remote" "cd /deploy-sourcegraph-docker && sudo tar --create --gzip -- *.log" | tar --extract --gzip || true
	exit "$exit_code"
fi
