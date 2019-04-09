#!/usr/bin/env bash
set -e

# Description: Redis for storing short-lived caches.
#
# CPU: 1
# Memory: 6GB
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
    -v ~/sourcegraph-docker/redis-cache-disk:/redis-data \
    sourcegraph/redis-cache:18-10-28_ba610fdf@sha256:10a4430cb8bb9c0ad2b96eac40882509fb1b11cbd77cffd0900f74a58a4014d2

echo "Deployed redis-cache service"