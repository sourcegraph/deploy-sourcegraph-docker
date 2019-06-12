#!/usr/bin/env bash
set -e
source ./replicas.sh

docker rm -f apache &> /dev/null || true &
docker rm -f cadvisor &> /dev/null || true &
docker rm -f sourcegraph-frontend-internal &> /dev/null || true &
docker rm -f $(addresses "sourcegraph-frontend-" $NUM_FRONTEND "") &> /dev/null || true &
docker rm -f github-proxy &> /dev/null || true &
docker rm -f $(addresses "gitserver-" $NUM_GITSERVER "") &> /dev/null || true &
docker rm -f grafana &> /dev/null || true
docker rm -f jaeger-agent &> /dev/null || true
docker rm -f jaeger-cassandra &> /dev/null || true
docker rm -f jaeger-collector &> /dev/null || true
docker rm -f jaeger-query &> /dev/null || true
docker rm -f jaeger-cassandra-schema &> /dev/null || true
docker rm -f lsif-server &> /dev/null || true
docker rm -f management-console &> /dev/null || true &
docker rm -f pgsql &> /dev/null || true &
docker rm -f prometheus &> /dev/null || true
docker rm -f query-runner &> /dev/null || true &
docker rm -f redis-cache &> /dev/null || true &
docker rm -f redis-store &> /dev/null || true &
docker rm -f replacer &> /dev/null || true &
docker rm -f repo-updater &> /dev/null || true &
docker rm -f $(addresses "searcher-" $NUM_SEARCHER "") &> /dev/null || true &
docker rm -f $(addresses "symbols-" $NUM_SYMBOLS "") &> /dev/null || true &
docker rm -f syntect-server &> /dev/null || true &
docker rm -f zoekt-indexserver &> /dev/null || true &
docker rm -f zoekt-webserver &> /dev/null || true &

docker network rm sourcegraph &> /dev/null || true &
wait