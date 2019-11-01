#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for indexed text search operations.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 6072/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=zoekt-indexserver-$1 \
    --hostname=zoekt-indexserver-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=8 \
    --memory=16g \
    -e GOMAXPROCS=8 \
    -e SRC_FRONTEND_INTERNAL=http://sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/zoekt-$1-shared-disk:/data/index \
    sourcegraph/zoekt-indexserver:0.0.20191022120547-c1011d8@sha256:28d07f9f0f233bea6e7839c7a89dcc2c421ab80351369336f1cbee0880141c3a

echo "Deployed zoekt-indexserver $1 service"
