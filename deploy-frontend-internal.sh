#!/usr/bin/env bash
set -e

# Description: Serves the internal Sourcegraph frontend API.
#
# CPU: 2
# Memory: 4GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3090
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=sourcegraph-frontend-internal \
    --network=sourcegraph \
    --restart=always \
    -e PGHOST=pgsql \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e SEARCHER_URL=http://searcher-0:3181 \
    -e SYMBOLS_URL=http://symbols-0:3184 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e REPO_UPDATER_URL=http://repo-updater:3182 \
    -e ZOEKT_HOST=zoekt-webserver:6070 \
    sourcegraph/frontend:3.0.0-alpha.9

echo "Deployed sourcegraph-frontend-internal service"