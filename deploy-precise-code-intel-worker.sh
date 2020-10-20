#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Handles conversion of uploaded precise code intelligence bundles.
#
# Ports exposed to other Sourcegraph services: 3188/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=precise-code-intel-worker \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=4g \
    -e 'PRECISE_CODE_INTEL_BUNDLE_MANAGER_URL=http://precise-code-intel-bundle-manager:3187' \
    -e 'SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090' \
    index.docker.io/sourcegraph/precise-code-intel-worker:3.19.1@sha256:f8f8c6d5f203ec00578f17d7ce229509e6641ae80a8549128a8928d255188f56

echo "Deployed precise-code-intel-worker service"
