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
    index.docker.io/sourcegraph/redis-store:3.41.1@sha256:f855f0e048d33bc94fd3103e14ee417d52434a7ab171dc3ee011b27aef0136bd

echo "Deployed redis-store service"
