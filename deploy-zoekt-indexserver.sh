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
    --name=zoekt-indexserver \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=6g \
    -e GOMAXPROCS=4 \
    -e SRC_FRONTEND_INTERNAL=http://sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/zoekt-shared-disk:/data/index \
    sourcegraph/zoekt-indexserver:19-06-13_f4122ec@sha256:7f8feae2f9c5487387aff62767cb589a63498acb1412263894bdc9756fa03b1a

echo "Deployed zoekt-indexserver service"