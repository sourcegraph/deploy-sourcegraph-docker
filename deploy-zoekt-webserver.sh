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
VOLUME="$HOME/sourcegraph-docker/zoekt-$1-shared-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=zoekt-webserver-$1 \
    --hostname=zoekt-webserver-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=16 \
    --memory=100g \
    -e GOMAXPROCS=16 \
    -e HOSTNAME=zoekt-webserver-$1:6070 \
    -v $VOLUME:/data/index \
    index.docker.io/sourcegraph/indexed-searcher:3.19.0@sha256:d2e87635cf48c4c5d744962540751022013359bc00a9fb8e1ec2464cc6a0a2b8

echo "Deployed zoekt-webserver $1 service"
