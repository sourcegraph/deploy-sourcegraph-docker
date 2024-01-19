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
    us-central1-docker.pkg.dev/sourcegraph-ci/rfc795-internal/redis-cache:5.3.666@sha256:7b5f4501ec28696b9c842def4217f03e21e687c824c277623425f9acddf1def8

echo "Deployed redis-cache service"
