#!/usr/bin/env bash
set -e

# Description: Redis for storing short-lived caches.
#
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
    index.docker.io/sourcegraph/redis-cache:20-01-30_c903717e@sha256:c069a4589420bc6d18a7d09ebaf5416fa6407666770cf650566dfd450bba65cf

echo "Deployed redis-cache service"