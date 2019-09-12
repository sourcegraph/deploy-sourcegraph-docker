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
    sourcegraph/zoekt-webserver:2019.08.19-014a202@sha256:1f1420ed341c3f7bc3041cd46c4bf1eba97b830aeffce9640472daccb2621788

echo "Deployed zoekt-webserver service"
