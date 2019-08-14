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
    sourcegraph/zoekt-webserver:19-08-14_75b5f54@sha256:aa1265e39823a02d9a58f0b72c696bc0fd80320d2036e63be28a95892859e0fd

echo "Deployed zoekt-webserver service"
