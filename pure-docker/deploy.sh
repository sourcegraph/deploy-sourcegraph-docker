#!/usr/bin/env bash
set -e

root_dir="$(dirname "${BASH_SOURCE[0]}")"
cd "$root_dir"

source ./replicas.sh

./teardown.sh

docker network create sourcegraph &>/dev/null || true

./deploy-apache.sh
./deploy-cadvisor.sh
./deploy-github-proxy.sh
for i in $(seq 0 $(($NUM_GITSERVER - 1))); do ./deploy-gitserver.sh $i; done
./deploy-grafana.sh
./deploy-precise-code-intel-worker.sh
./deploy-pgsql.sh
./deploy-codeintel-db.sh
./deploy-codeinsights-db.sh
./deploy-minio.sh
./deploy-prometheus.sh
./deploy-redis-cache.sh
./deploy-redis-store.sh
./deploy-repo-updater.sh
./deploy-worker.sh
./deploy-otel-collector.sh
for i in $(seq 0 $(($NUM_SEARCHER - 1))); do ./deploy-searcher.sh $i; done
for i in $(seq 0 $(($NUM_SYMBOLS - 1))); do ./deploy-symbols.sh $i; done
./deploy-syntect-server.sh
for i in $(seq 0 $(($NUM_INDEXED_SEARCH - 1))); do ./deploy-zoekt-indexserver.sh $i; done
for i in $(seq 0 $(($NUM_INDEXED_SEARCH - 1))); do ./deploy-zoekt-webserver.sh $i; done

./deploy-migrator.sh
while [ "$(docker inspect migrator --format '{{.State.Status}}')" != "exited" ]; do
  echo "waiting for migrator to complete"
  sleep 5
done

# Redis must be started before these.
./deploy-frontend-internal.sh
# Wait for frontend-internal to run migrations before starting remaining frontend containers
while [ "$(docker inspect sourcegraph-frontend-internal --format '{{.State.Health.Status}}')" != "healthy" ]; do
  echo "waiting for internal frontend to start"
  sleep 5
done

for i in $(seq 0 $(($NUM_FRONTEND - 1))); do ./deploy-frontend.sh $i; done
# Not used in customer-replica branch.
#./deploy-caddy.sh
wait
