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
    --memory=60g \
    -v ~/sourcegraph-docker/zoekt-shared-disk:/data/index \
    sourcegraph/zoekt-webserver:18-10-30_faca01d@sha256:afadb33c9c254256fc41a6cbd372d2eca93140eebc1fee05367fd81059ea7205

echo "Deployed zoekt-webserver service"