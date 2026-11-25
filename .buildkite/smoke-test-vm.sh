#!/usr/bin/env bash

# Runs test/smoke-test.sh and test/executor-smoke-test.sh on a new GCP VM booted from $IMAGE,
# then deletes the VM

cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -euo pipefail

project="sourcegraph-ci"
zone="us-central1-f"

# GCP creates a disk, then a VM, both with the same name. Naming them after the job
# lets the cleanup find them if the job is cancelled before the VM exists
instance_name_prefix="docker-test-job-"
instance_name="${instance_name_prefix}${BUILDKITE_JOB_ID}"

# The builder account key, and an SSH key for this job only
temporary_directory="$(mktemp -d)"

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

cleanup() {
	request_deletion "name=${instance_name}" ||
		echo "Could not delete this job's VM. GCP deletes it an hour after it started"
	rm -rf "$temporary_directory"
}
trap cleanup EXIT

# The VM's guest agent authorizes this key for the buildkite user.
# The keepalive ends the connection to a VM which stopped answering, after a minute
ssh-keygen -q -t ed25519 -N "" -C buildkite -f "$temporary_directory/ssh-key"
ssh_options=(-i "$temporary_directory/ssh-key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR
	-o ConnectTimeout=5 -o ServerAliveInterval=15 -o ServerAliveCountMax=4)

echo --- ":lock: builder account key"
gcloud secrets versions access latest --secret=e2e-builder-sa-key --quiet --project="$project" >"$temporary_directory/builder-key.json"
DOCKER_PASSWORD="$(gcloud secrets versions access latest --secret=DOCKER_PASSWORD_BUILDKITE_AGENT --quiet --project="$project")"
export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="$temporary_directory/builder-key.json"

echo --- ":wastebasket: deleting VMs and disks left behind by jobs which died before their cleanup"
# The smoke test step times out after 30 minutes, so a VM or disk older than an hour has no job.
# GCP deletes the VMs itself after an hour, but not a disk whose VM was never created
request_deletion "name~^${instance_name_prefix} AND creationTimestamp<-PT1H" || echo "Could not delete stale VMs and disks"

echo "--- :gcloud: starting VM $instance_name"
# `beta`, because --max-run-duration is only there in the agents' gcloud 417. It is in every track from gcloud 483
ip_address="$(gcloud beta compute instances create "$instance_name" \
	--project="$project" --zone="$zone" \
	--image="$IMAGE" --image-project="$project" \
	--machine-type=custom-16-20480 \
	--boot-disk-size=20GB --boot-disk-type=pd-standard \
	--max-run-duration=1h --instance-termination-action=DELETE \
	--network=default --no-address \
	--service-account="e2e-builder@${project}.iam.gserviceaccount.com" --scopes=compute-rw,storage-ro \
	--labels=team=dev-infra,type=smoke-test \
	--metadata="ssh-keys=buildkite:$(cat "$temporary_directory/ssh-key.pub")" \
	--format="value(networkInterfaces[0].networkIP)")"
remote="buildkite@${ip_address}"

echo --- ":ssh: waiting for the VM to accept SSH"
deadline=$((SECONDS + 300))
until ssh "${ssh_options[@]}" "$remote" true; do
	if ((SECONDS > deadline)); then
		echo "The VM did not accept SSH within 5 minutes"
		exit 1
	fi
	sleep 2
done

copy_repository() {
	tar --create --gzip --exclude=.git --exclude=node_modules . |
		ssh "${ssh_options[@]}" "$remote" "sudo mkdir -p /deploy-sourcegraph-docker && sudo tar --extract --gzip --directory=/deploy-sourcegraph-docker"
}

echo --- ":package: copying the repository to the VM"
# A VM can accept SSH, then stop answering for a while. ssh exits with 255 when the connection fails,
# so retry the copy on the same VM. The tests have not started yet, so nothing runs twice
exit_code=0
copy_repository || exit_code=$?
for retry in {1..10}; do
	if [ "$exit_code" != 255 ]; then
		break
	fi
	echo "The VM does not answer SSH, retry $retry of 10 in 15 seconds"
	sleep 15
	exit_code=0
	copy_repository || exit_code=$?
done

if [ "$exit_code" = 0 ]; then
	echo --- ":docker: running the smoke tests"
	# Runs as root on the VM. The Docker Hub password comes over stdin, so it does not show in the VM's process list
	remote_script='
set -euo pipefail
read -r DOCKER_PASSWORD
export DOCKER_USERNAME=sourcegraph DOCKER_PASSWORD
/deploy-sourcegraph-docker/test/smoke-test.sh
# The Ubuntu 20.04 VM image has no jq. Skip /etc/apt/sources.list.d: that image lacks the key for its Chrome repository, so a full update fails
command -v jq >/dev/null || { apt-get update --quiet --option Dir::Etc::sourceparts=- && apt-get install --quiet --yes jq; }
/deploy-sourcegraph-docker/test/executor-smoke-test.sh
'
	# shellcheck disable=SC2029 # remote_script is quoted here, to run on the VM
	ssh "${ssh_options[@]}" "$remote" "sudo bash -c $(printf %q "$remote_script")" <<<"$DOCKER_PASSWORD" || exit_code=$?

	if [ "$exit_code" != 0 ]; then
		# Copy back the container logs the smoke test wrote, for the step's artifacts
		ssh "${ssh_options[@]}" "$remote" "cd /deploy-sourcegraph-docker && sudo tar --create --gzip -- *.log" | tar --extract --gzip || true
	fi
fi

# Not a plain `exit`, after which shellcheck reports that cleanup is never invoked (SC2329)
[ "$exit_code" = 0 ] || exit "$exit_code"
