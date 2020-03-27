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
docker run --detach \
    --name=sourcegraph-frontend-internal \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    -e GOMAXPROCS=4 \
    -e PGHOST=pgsql \
    -e SRC_GIT_SERVERS="$(addresses "gitserver-" $NUM_GITSERVER ":3178")" \
    -e SRC_SYNTECT_SERVER=http://syntect-server:9238 \
    -e SEARCHER_URL="$(addresses "http://searcher-" $NUM_SEARCHER ":3181")" \
    -e SYMBOLS_URL="$(addresses "http://symbols-" $NUM_SYMBOLS ":3184")" \
    -e INDEXED_SEARCH_SERVERS="$(addresses "zoekt-webserver-" $NUM_INDEXED_SEARCH ":6070")" \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e REPO_UPDATER_URL=http://repo-updater:3182 \
    -e REPLACER_URL=http://replacer:3185 \
    # remove after 3.15
    -e LSIF_SERVER_URL=http://lsif-server:3186 \
    # used after 3.15
    -e LSIF_API_SERVER_URL=http://lsif-server:3186 \
    -e GRAFANA_SERVER_URL=http://grafana:3000 \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -v ~/sourcegraph-docker/sourcegraph-frontend-internal-0-disk:/mnt/cache \
    index.docker.io/sourcegraph/frontend:3.14.0@sha256:fd10d228461581e65fcc39e0fc4481be5a19f4b5aa1a1b19f0ad90fcc4a5ff88

echo "Deployed sourcegraph-frontend-internal service"
