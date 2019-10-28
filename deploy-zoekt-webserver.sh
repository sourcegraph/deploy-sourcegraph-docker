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
    --cpus=16 \
    --memory=100g \
    -e GOMAXPROCS=16 \
    -v ~/sourcegraph-docker/zoekt-shared-disk:/data/index \
    sourcegraph/zoekt-webserver:0.0.20191022120331-c1011d8@sha256:90a5e974a24779722c08c3da881ba43b0e99f6f3a47f8acbc5db24789b0573f6

echo "Deployed zoekt-webserver service"
