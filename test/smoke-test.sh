#!/usr/bin/env bash
set -euxfo pipefail

configure_docker() {
  gcloud auth configure-docker
  gcloud auth configure-docker us-central1-docker.pkg.dev
}

deploy_sourcegraph() {
	cd $(dirname "${BASH_SOURCE[0]}")/..
	#Deploy sourcegraph
	if [[ "$TEST_TYPE" == "pure-docker-test" ]]; then
		./test/volume-config.sh
		timeout 600s ./pure-docker/deploy.sh
		expect_containers="25"
	elif [[ "$TEST_TYPE" == "docker-compose-test" ]]; then
		docker-compose --file docker-compose/docker-compose.yaml up -d -t 600
		expect_containers="27"
	fi

	echo "Giving containers 90s to start..."
	sleep 90
}

test_count() {
	echo "TEST: Number of expected containers created"
	containers_count=$(docker ps --format '{{.Names}}' | wc -l)
	if [[ "$containers_count" -ne "$expect_containers" ]]; then
		docker ps --format '{{.Names}}'
		echo
		echo "TEST FAILURE: expected $expect_containers containers, found $containers_count"
		exit 1
	fi
}

test_containers() {
	echo "TEST: Checking every 10s that containers are running for 5 minutes..."
	for i in {0..1}; do
		containers=$(docker ps --format '{{.Names}}' | xargs -I{} -n1 sh -c "printf '{}: ' && docker inspect --format '{{.State.Status}}' {}")
		containers_running=$(echo "$containers" | grep -c "running")
		if [[ "$containers_running" -ne "$expect_containers" ]]; then
			containers_failing=$(docker ps --format '{{.Names}}:{{.Status}}' | grep -v Up | cut -f 1 -d :)
			echo "TEST FAILURE: expected $expect_containers containers running, found $containers_running. The following containers are failing: $containers_failing"
			exit 1
		fi
		echo "Containers running OK.. waiting 10s"
		sleep 1
	done

	echo "TEST: Checking frontend is accessible"
	curl -f http://localhost:80
	curl -f http://localhost:80/healthz

	echo "ALL TESTS PASSED"
}

catch_errors() {
	count=$(docker ps --format '{{.Names}}:{{.Status}}' | grep -c -v Up) || true
	if [[ $count -ne 0 ]]; then
		containers_failing=$(docker ps --format '{{.Names}}:{{.Status}}' | grep -v Up | cut -f 1 -d :)
		echo
		for cf in $containers_failing; do
			echo "$cf is failing. Review the log files uploaded as artefacts to see errors."
			docker logs -t "$cf" >"$cf".log 2>&1
		done
		exit 1
	fi
}

trap catch_errors EXIT

configure_docker
deploy_sourcegraph
test_count
test_containers
