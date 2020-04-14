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
    index.docker.io/sourcegraph/indexed-searcher:insiders@sha256:d48de388d28899fd0c3ad0d6f84d466b3a1f533f6b967a713918d438ab8bc63c

echo "Deployed zoekt-webserver $1 service"
