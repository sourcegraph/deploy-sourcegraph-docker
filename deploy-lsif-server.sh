#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: LSIF HTTP server for code intelligence.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://lsif-server:3186/healthz
# Ports exposed to other Sourcegraph services: 3186/TCP (server) 9090/TCP (prometheus)
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=lsif-server \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=2g \
    -e GOMAXPROCS=2 \
    -e NUM_APIS=1 \
    -e NUM_BUNDLE_MANAGERS=1 \
    -e NUM_WORKERS=1 \
    -e LSIF_STORAGE_ROOT=/lsif-storage \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/lsif-server-disk:/lsif-storage \
    index.docker.io/sourcegraph/lsif-server:3.13.2@sha256:27d6f82702cd770d02de57a8a74b8b1f338ee3de53eb3979bd2a06f12216bf7e

echo "Deployed lsif-server service"
