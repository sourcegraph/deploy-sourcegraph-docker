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
    index.docker.io/sourcegraph/precise-code-intel-api-server:3.15.1@sha256:ee80ffbd8b2d50c9cd8a38ed2e02f4e4be0886557089d56525d71e601d3a74e7

echo "Deployed precise-code-intel-api-server service"
