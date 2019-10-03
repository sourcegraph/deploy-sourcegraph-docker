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
    --cpus=8 \
    --memory=16g \
    -e GOMAXPROCS=8 \
    -e SRC_FRONTEND_INTERNAL=http://sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/zoekt-shared-disk:/data/index \
    sourcegraph/zoekt-indexserver:0.0.20190924205126-699d5c5@sha256:1ad7236a7c0cae4c0d49462ff8c22a66748cf08b78ad85656f08ff98919e61fc

echo "Deployed zoekt-indexserver service"
