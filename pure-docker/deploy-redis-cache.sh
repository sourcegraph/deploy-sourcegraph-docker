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
VOLUME="$HOME/sourcegraph-docker/redis-cache-disk"
./ensure-volume.sh $VOLUME 999
docker run --detach \
    --name=redis-cache \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=6g \
    -v $VOLUME:/redis-data \
    index.docker.io/sourcegraph/redis-cache:5.1.5@sha256:fcf38d687c2130a56bed3a17fba7340948484ef2b096c1dc874716a308635d81

echo "Deployed redis-cache service"
