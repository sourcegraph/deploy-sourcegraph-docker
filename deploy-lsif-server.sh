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
    index.docker.io/sourcegraph/lsif-server:3.11.4@sha256:b6b84c1f552a11a445bf74bf2d8059ba2ad5527d01961d953f86f4596dafc91a

echo "Deployed lsif-server service"
