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
    index.docker.io/sourcegraph/redis-store:4.1.2@sha256:8b7febb5d4802e80423fa3bf66a8f8fd473cf2e219c685d296f5d1a1e1d27278

echo "Deployed redis-store service"
