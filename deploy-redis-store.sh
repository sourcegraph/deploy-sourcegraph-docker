#!/usr/bin/env bash
set -e

# Description: Redis for storing semi-persistent data like user sessions.
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
    --name=redis-store \
    --network=sourcegraph \
    --restart=always \
    -v ~/sourcegraph-docker/redis-store-disk:/redis-data \
    sourcegraph/redis-store:18-10-28_e45f6d82@sha256:1fe101e1f04a8e267fda85c342cd3b974ab4a9e47718b864752f14f1da51579c \

echo "Deployed redis-store service"