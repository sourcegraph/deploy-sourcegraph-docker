#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for indexed text search operations.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://zoekt-webserver-$1:6070/healthz
# Ports exposed to other Sourcegraph services: 6070/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=zoekt-webserver-$1 \
    --hostname=zoekt-webserver-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=16 \
    --memory=100g \
    -e GOMAXPROCS=16 \
    -e HOSTNAME=zoekt-webserver-$1:6070 \
    -v ~/sourcegraph-docker/zoekt-$1-shared-disk:/data/index \
    index.docker.io/sourcegraph/zoekt-webserver:0.0.20200124185328-83b89a5@sha256:cde27ee7db0fe6c293a8c9df47b529fb01b5a898e6cbeea4c18d80fe218563db

echo "Deployed zoekt-webserver $1 service"
