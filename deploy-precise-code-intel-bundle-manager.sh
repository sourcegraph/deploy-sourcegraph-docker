#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Stores and manages precise code intelligence bundles.
#
# Disk: 200GB / persistent SSD
# Ports exposed to other Sourcegraph services: 3187/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/lsif-server-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=precise-code-intel-bundle-manager \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=2g \
    -e 'SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090' \
    -v ~/sourcegraph-docker/lsif-server-disk:/lsif-storage \
    index.docker.io/sourcegraph/precise-code-intel-bundle-manager:3.19.1@sha256:7bfad68ae5c89c0825bdee1f5c5fa26c8605323044f7999d56ca92e0d8820dc0

echo "Deployed precise-code-intel-bundle-manager service"
