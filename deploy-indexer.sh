#!/usr/bin/env bash
set -e

# Description: Asynchronous indexing for global references.
#
# CPU: 1
# Memory: 1GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3179/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=indexer \
    --network=sourcegraph \
    --restart=always \
    -e PGHOST=pgsql \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    sourcegraph/indexer:3.0.0-alpha.4

echo "Deployed indexer service"