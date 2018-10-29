#!/usr/bin/env bash
set -e

./teardown.sh

docker network create sourcegraph &> /dev/null || true

./deploy-github-proxy.sh
./deploy-gitserver.sh
./deploy-indexer.sh
./deploy-pgsql.sh
./deploy-query-runner.sh
./deploy-redis-cache.sh
./deploy-redis-store.sh
./deploy-repo-updater.sh
./deploy-searcher.sh
./deploy-symbols.sh
./deploy-syntect-server.sh
./deploy-zoekt-indexserver.sh
./deploy-zoekt-webserver.sh

# Redis must be started before these.
./deploy-frontend-internal.sh
./deploy-frontend.sh
