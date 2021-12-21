#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Serves the internal Sourcegraph frontend API.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3090/TCP 6060/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/sourcegraph-frontend-internal-0-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=sourcegraph-frontend-internal \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    --health-cmd="wget -q 'http://127.0.0.1:3080/healthz' -O /dev/null || exit 1" \
    --health-interval=5s \
    --health-timeout=10s \
    --health-retries=3 \
    --health-start-period=300s \
    -e DEPLOY_TYPE=pure-docker \
    -e GOMAXPROCS=4 \
    -e PGHOST=pgsql \
    -e CODEINTEL_PGHOST=codeintel-db \
    -e CODEINSIGHTS_PGDATASOURCE=postgres://postgres:password@codeinsights-db:5432/postgres \
    -e SRC_GIT_SERVERS="$(addresses "gitserver-" $NUM_GITSERVER ":3178")" \
    -e SRC_SYNTECT_SERVER=http://syntect-server:9238 \
    -e SEARCHER_URL="$(addresses "http://searcher-" $NUM_SEARCHER ":3181")" \
    -e SYMBOLS_URL="$(addresses "http://symbols-" $NUM_SYMBOLS ":3184")" \
    -e INDEXED_SEARCH_SERVERS="$(addresses "zoekt-webserver-" $NUM_INDEXED_SEARCH ":6070")" \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e REPO_UPDATER_URL=http://repo-updater:3182 \
    -e GRAFANA_SERVER_URL=http://grafana:3000 \
    -e JAEGER_SERVER_URL=http://jaeger:16686 \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -e PROMETHEUS_URL=http://prometheus:9090 \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/frontend:3.35.0@sha256:4219bdb2f5d2d7e32e7df6c183bd8e8d888a90ae52e866534183804c123ab4f4

echo "Deployed sourcegraph-frontend-internal service"
