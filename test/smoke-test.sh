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

# Every service a customer can deploy, started and checked by the same commands
compose_files=(
	--file docker-compose/docker-compose.yaml
	--file docker-compose/jaeger/docker-compose.yaml
	--file docker-compose/executors/executor.docker-compose.yaml
	--file test/docker-compose.override.yaml
)

deploy_sourcegraph() {
	cd "$(dirname "${BASH_SOURCE[0]}")/.."
	# The Ubuntu 20.04 VM image only has the standalone docker-compose 1.29.2
	if docker compose version; then
		compose=(docker compose)
	else
		compose=(docker-compose)
		docker-compose version
	fi
	# `up` pulls images one at a time, `pull` pulls them in parallel
	"${compose[@]}" "${compose_files[@]}" pull --quiet
	"${compose[@]}" "${compose_files[@]}" up -d -t 600
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
	expect_containers=$("${compose[@]}" "${compose_files[@]}" config --services | grep --count --invert-match '^migrator$')
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

	echo "TEST: Checking Jaeger is accessible"
	curl --fail --silent --show-error --location --output /dev/null http://localhost:16686/-/debug/jaeger/

	echo "ALL TESTS PASSED"
}

# On failure, save every container's logs, which the CI step uploads as artifacts
save_logs_on_failure() {
	exit_code=$?
	if [[ $exit_code -ne 0 ]]; then
		docker ps --all --format '{{.Names}}: {{.Status}}'
		for container in $(docker ps --all --format '{{.Names}}'); do
			docker logs --timestamps "$container" >"$container.log" 2>&1 || true
		done
	fi
}

trap save_logs_on_failure EXIT

configure_docker
deploy_sourcegraph
wait_until_healthy
test_count
test_containers
