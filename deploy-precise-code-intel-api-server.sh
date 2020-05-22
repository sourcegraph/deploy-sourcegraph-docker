#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Serves precise code intelligence requests.
#
# Ports exposed to other Sourcegraph services: 3186/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=precise-code-intel-api-server \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=2g \
    -e 'PRECISE_CODE_INTEL_BUNDLE_MANAGER_URL=http://precise-code-intel-bundle-manager:3187' \
    -e 'SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090' \
    index.docker.io/sourcegraph/precise-code-intel-api-server:3.16.0@sha256:3a02d6ac32ab319050bbfd9b3a82d1ce00a2c262fcde57dc884f00bdb5a1513a

echo "Deployed precise-code-intel-api-server service"
