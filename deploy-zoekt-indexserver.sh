#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for indexed text search operations.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 6072/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=zoekt-indexserver \
    --network=sourcegraph \
    --restart=always \
    --cpus=8 \
    --memory=8g \
    -e GOMAXPROCS=8 \
    -e SRC_FRONTEND_INTERNAL=http://sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/zoekt-shared-disk:/data/index \
    sourcegraph/zoekt-indexserver:0.0.20190913055037-b3e888a@sha256:1c5b3bf30438907aab2d791d296111c42ca72afab6a8f29d4286d32b02fa0277

echo "Deployed zoekt-indexserver service"
