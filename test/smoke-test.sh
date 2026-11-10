#!/usr/bin/env bash
set -euxfo pipefail

configure_docker() {
  set +x
  if [ -n "${DOCKER_USERNAME:-}" ] && [ -n "${DOCKER_PASSWORD:-}" ]; then
    docker login -u "${DOCKER_USERNAME}" --password-stdin <<<"$DOCKER_PASSWORD"
  fi
  set -x
  gcloud auth configure-docker
  gcloud auth configure-docker us-central1-docker.pkg.dev,us-docker.pkg.dev
}

deploy_sourcegraph() {
	cd "$(dirname "${BASH_SOURCE[0]}")/.."
	docker-compose version
	# `up` pulls images one at a time, `pull` pulls them in parallel
	docker-compose --file docker-compose/docker-compose.yaml pull --quiet
	docker-compose --file docker-compose/docker-compose.yaml up -d -t 600
}

wait_until_healthy() {
	echo "Waiting up to 5 minutes for the frontend to respond, and container health checks to pass..."
	for _ in {1..60}; do
		if curl --fail --silent --output /dev/null http://localhost:80/healthz &&
			[[ -z "$(docker ps --quiet --filter health=starting --filter health=unhealthy)" ]]; then
			return
		fi
		sleep 5
	done
	docker ps --format '{{.Names}}: {{.Status}}'
	echo "TEST FAILURE: containers were not healthy after 5 minutes"
	exit 1
}

test_count() {
	echo "TEST: Every service has a running container"
	# migrator exits when it is done, every other service keeps running
	expect_containers=$(docker-compose --file docker-compose/docker-compose.yaml config --services | grep --count --invert-match '^migrator$')
	containers_count=$(docker ps --filter status=running --format '{{.Names}}' | wc -l)
	if [[ "$containers_count" -ne "$expect_containers" ]]; then
		docker ps --all --format '{{.Names}}: {{.Status}}'
		echo
		echo "TEST FAILURE: expected $expect_containers running containers, found $containers_count"
		exit 1
	fi
}

test_containers() {
	echo "TEST: No container has restarted"
	restarted_containers=$(docker ps --quiet | xargs docker inspect --format '{{.Name}} restarted {{.RestartCount}} times' | grep -v ' restarted 0 times' || true)
	if [[ -n "$restarted_containers" ]]; then
		echo "TEST FAILURE: $restarted_containers"
		exit 1
	fi

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
wait_until_healthy
test_count
test_containers
