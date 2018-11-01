#!/usr/bin/env bash
set -e

# Description: Backend for text search operations.
#
# CPU: 2
# Memory: 2GB
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://searcher:3181/healthz
# Ports exposed to other Sourcegraph services: 3181/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=searcher-0 \
    --network=sourcegraph \
    --restart=always \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/searcher-disk:/mnt/cache \
    sourcegraph/searcher:3.0.0-alpha.2

echo "Deployed searcher service"