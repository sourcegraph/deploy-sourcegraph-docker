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
    -e 'SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090' \
    index.docker.io/sourcegraph/precise-code-intel-worker:insiders@sha256:b635e06165d1e6a4ca7573f7aa97baba7e392d88b83d7cee8752928202db94a1

echo "Deployed precise-code-intel-worker service"
