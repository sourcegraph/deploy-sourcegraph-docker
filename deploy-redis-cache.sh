#!/usr/bin/env bash
set -e

# Description: Redis for storing short-lived caches.
#
# Disk: 128GB / persistent SSD
# Network: 100mbps
# Liveness probe: 6379/TCP
# Ports exposed to other Sourcegraph services: 6379/TCP 9121/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=redis-cache \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=6g \
    -v ~/sourcegraph-docker/redis-cache-disk:/redis-data \
    index.docker.io/sourcegraph/redis-cache:insiders@sha256:7820219195ab3e8fdae5875cd690fed1b2a01fd1063bd94210c0e9d529c38e56

echo "Deployed redis-cache service"