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
    index.docker.io/sourcegraph/precise-code-intel-worker:3.32.0@sha256:f3a1bbe3b63a8c81d6fec91b73f6f82f16ce70b4f73913a8845b2e54863d6819

echo "Deployed precise-code-intel-worker service"
