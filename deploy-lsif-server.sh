#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: LSIF HTTP server for code intelligence.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3186/TCP (server) 3187/TCP (worker)
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=lsif-server \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=2g \
    -e GOMAXPROCS=2 \
    -e LSIF_STORAGE_ROOT=/lsif-storage \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/lsif-server-disk:/lsif-storage \
    sourcegraph/lsif-server:3.9.4@sha256:15496304027e37716e3b8665043dcf497a1f4842c97327c3067f888f610b4c2b

echo "Deployed lsif-server service"
