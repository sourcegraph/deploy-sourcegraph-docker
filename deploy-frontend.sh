#!/usr/bin/env bash
set -e

# Description: Serves the frontend of Sourcegraph via HTTP(S).
#
# CPU: 2
# Memory: 4GB
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://sourcegraph-frontend:3080/healthz
# Ports exposed to other Sourcegraph services: none
# Ports exposed to the public internet: 3080 (HTTP) and/or 3443 (HTTPS)
#
docker run --detach \
    --name=sourcegraph-frontend \
    --network=sourcegraph \
    --restart=always \
    -e PGHOST=pgsql \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e SEARCHER_URL=http://searcher-0:3181 \
    -e SYMBOLS_URL=http://symbols-0:3184 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e REPO_UPDATER_URL=http://repo-updater:3182 \
    -e ZOEKT_HOST=zoekt-webserver:6070 \
    -v ~/sourcegraph-docker/sourcegraph-frontend-disk:/mnt/cache \
    -p 127.0.0.1:3080:3080 \
    sourcegraph/frontend:3.0.0-beta.2

# Note: SRC_GIT_SERVERS, SEARCHER_URL, and SYMBOLS_URL are space-separated
# lists which each allow you to specify more container instances for scaling
# purposes. Be sure to also apply such a change here to the frontend-internal
# service.

echo "Deployed sourcegraph-frontend service"
