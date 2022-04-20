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
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST=jaeger \
    index.docker.io/sourcegraph/precise-code-intel-worker:3.39.0@sha256:3fe57e9e5b6f6b43b6fc4cf6ca36d35fce7c34234933e569ec9976c11c01ba42

echo "Deployed precise-code-intel-worker service"
