#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Stores and manages precise code intelligence bundles.
#
# Disk: 200GB / persistent SSD
# Ports exposed to other Sourcegraph services: 3187/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=precise-code-intel-bundle-manager \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=2g \
    -e 'SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090' \
    -v ~/sourcegraph-docker/lsif-server-disk:/lsif-storage \
    index.docker.io/sourcegraph/precise-code-intel-bundle-manager:3.19.0@sha256:b2f7bba886b53147637f8721606db80cb7d45d7a3ee36f6674a7f99ddb451f38

echo "Deployed precise-code-intel-bundle-manager service"
