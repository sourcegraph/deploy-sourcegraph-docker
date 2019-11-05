#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for replace operations.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: GET http://replacer:3185/healthz
# Ports exposed to other Sourcegraph services: 3185/TCP 6060/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=replacer \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=512m \
    -e GOMAXPROCS=1 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/replacer-disk:/mnt/cache \
    sourcegraph/replacer:3.9.4@sha256:e35a392a63e21d5be556676791e80b9547f8a05d8031ca4a21e982dfd9c8ebeb

echo "Deployed replacer service"