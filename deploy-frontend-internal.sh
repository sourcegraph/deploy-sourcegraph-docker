#!/usr/bin/env bash
set -e

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
    --memory=4g \
    -e PGHOST=pgsql \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e SRC_SYNTECT_SERVER=http://syntect-server:9238 \
    -e SEARCHER_URL=http://searcher-0:3181 \
    -e SYMBOLS_URL=http://symbols-0:3184 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e REPO_UPDATER_URL=http://repo-updater:3182 \
    -e ZOEKT_HOST=zoekt-webserver:6070 \
    -v ~/sourcegraph-docker/sourcegraph-frontend-internal-0-disk:/mnt/cache \
    sourcegraph/frontend:3.2.1

echo "Deployed sourcegraph-frontend-internal service"
