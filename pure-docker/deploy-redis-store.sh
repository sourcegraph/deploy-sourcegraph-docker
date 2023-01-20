#!/usr/bin/env bash
set -e

# Description: Redis for storing semi-persistent data like user sessions.
#
# Disk: 128GB / persistent SSD
# Network: 100mbps
# Liveness probe: 6379/TCP
# Ports exposed to other Sourcegraph services: 6379/TCP 9121/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/redis-store-disk"
./ensure-volume.sh $VOLUME 999
docker run --detach \
    --name=redis-store \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=6g \
    -v $VOLUME:/redis-data \
    index.docker.io/sourcegraph/redis-store:4.4.0@sha256:8a8dbee0847e8c492b6cff6d61cc180e3cd4076c903d12d62a0de518bffcb7dc

echo "Deployed redis-store service"
