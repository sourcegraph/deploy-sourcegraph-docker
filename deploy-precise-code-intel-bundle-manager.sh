#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Stores and manages precise code intelligence bundles.
#
# Disk: 200GB / persistent SSD
# Ports exposed to other Sourcegraph services: 3187/TCP (manager)
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=precise-code-intel-bundle-manager \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=2g \
    -e 'PRECISE_CODE_INTEL_API_SERVER_URL=http://precise-code-intel-api-server:3186' \
    -e 'SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090' \
    -e 'LSIF_STORAGE_ROOT=/lsif-storage' \
    -v ~/sourcegraph-docker/lsif-server-disk:/lsif-storage \
    index.docker.io/sourcegraph/precise-code-intel-bundle-manager:59913_2020-04-02_5ae630c

echo "Deployed precise-code-intel-bundle-manager service"
