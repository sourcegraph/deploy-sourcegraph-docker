#!/usr/bin/env bash
set -e
source ./replicas.sh

./teardown.sh

docker network create sourcegraph &> /dev/null || true

./deploy-apache.sh
./deploy-cadvisor.sh
./deploy-github-proxy.sh &
for i in $(seq 0 $(($NUM_GITSERVER - 1))); do (./deploy-gitserver.sh $i &); done
./deploy-grafana.sh
# Disabled for now, see https://github.com/sourcegraph/sourcegraph/issues/5363
#./deploy-jaeger-agent.sh
#./deploy-jaeger-cassandra.sh
#./deploy-jaeger-collector.sh
#./deploy-jaeger-query.sh
#./init-jaeger-cassandra-schema.sh
./deploy-lsif-server.sh &
./deploy-management-console.sh &
./deploy-pgsql.sh &
./deploy-prometheus.sh
./deploy-query-runner.sh &
./deploy-redis-cache.sh &
./deploy-redis-store.sh &
./deploy-replacer.sh &
./deploy-repo-updater.sh &
for i in $(seq 0 $(($NUM_SEARCHER - 1))); do (./deploy-searcher.sh $i &); done
for i in $(seq 0 $(($NUM_SYMBOLS - 1))); do (./deploy-symbols.sh $i &); done
./deploy-syntect-server.sh &
./deploy-zoekt-indexserver.sh &
./deploy-zoekt-webserver.sh &
./deploy-a8n-ruby-bundler-exec.sh &

# Redis must be started before these.
./deploy-frontend-internal.sh
for i in $(seq 0 $(($NUM_FRONTEND - 1))); do (./deploy-frontend.sh $i &); done
wait
