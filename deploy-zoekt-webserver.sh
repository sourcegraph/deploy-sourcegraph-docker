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
    -e HOSTNAME=zoekt-webserver-$1:6070 \
    -e GOMAXPROCS=16 \
    -v ~/sourcegraph-docker/zoekt-$1-shared-disk:/data/index \
    sourcegraph/zoekt-webserver:0.0.20191031121751-5bd7e84@sha256:1afbfb746a3d43a7532693093d2f993dac5b5536037b31d3ab305ceef5687380

echo "Deployed zoekt-webserver $1 service"
