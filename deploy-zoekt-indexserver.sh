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
    -e SRC_FRONTEND_INTERNAL=http://sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/zoekt-shared-disk:/data/index \
    sourcegraph/zoekt-indexserver:18-10-30_faca01d@sha256:36c1309d935b7faf5ec69277444a6c0eefa510a6eb20deb651cdb7ce3de3913f

echo "Deployed zoekt-indexserver service"