#!/usr/bin/env bash
set -e

# Description: Backend for indexed text search operations.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://zoekt-webserver:6070/healthz
# Ports exposed to other Sourcegraph services: 6070/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=zoekt-webserver \
    --network=sourcegraph \
    --restart=always \
    --cpus=8 \
    --memory=80g \
    -e GOMAXPROCS=8 \
    -v ~/sourcegraph-docker/zoekt-shared-disk:/data/index \
    sourcegraph/zoekt-webserver:19-06-19_c84cd19@sha256:57a3eb4991540bf813fc62459719b2db3dbac540dd284088cd2e84081225531f

echo "Deployed zoekt-webserver service"