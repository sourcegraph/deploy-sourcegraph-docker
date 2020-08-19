#!/usr/bin/env bash
set -e
source ./replicas.sh

./teardown.sh

docker network create sourcegraph &> /dev/null || true

./deploy-cadvisor.sh
./deploy-github-proxy.sh
for i in $(seq 0 $(($NUM_GITSERVER - 1))); do ./deploy-gitserver.sh $i; done
./deploy-grafana.sh
./deploy-jaeger.sh
./deploy-precise-code-intel-bundle-manager.sh
./deploy-precise-code-intel-worker.sh
./deploy-pgsql.sh
./deploy-prometheus.sh
./deploy-query-runner.sh
./deploy-redis-cache.sh
./deploy-redis-store.sh
./deploy-repo-updater.sh
for i in $(seq 0 $(($NUM_SEARCHER - 1))); do ./deploy-searcher.sh $i; done
for i in $(seq 0 $(($NUM_SYMBOLS - 1))); do ./deploy-symbols.sh $i; done
./deploy-syntect-server.sh
for i in $(seq 0 $(($NUM_INDEXED_SEARCH - 1))); do ./deploy-zoekt-indexserver.sh $i; done
for i in $(seq 0 $(($NUM_INDEXED_SEARCH - 1))); do ./deploy-zoekt-webserver.sh $i; done

# Redis must be started before these.
./deploy-frontend-internal.sh
for i in $(seq 0 $(($NUM_FRONTEND - 1))); do ./deploy-frontend.sh $i; done
# Not used in customer-replica branch.
#./deploy-caddy.sh
wait
