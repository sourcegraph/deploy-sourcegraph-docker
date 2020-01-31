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
    index.docker.io/sourcegraph/redis-cache:19-04-16_6891de82@sha256:4cbfac8af0abb673899250d4fd859cc477d6426de519e9deb71e454e18322499

echo "Deployed redis-cache service"