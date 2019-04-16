#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for text search operations.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://searcher:3181/healthz
# Ports exposed to other Sourcegraph services: 3181/TCP 6060/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=searcher-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=2g \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST='jaeger-agent' \
    -v ~/sourcegraph-docker/searcher-$1-disk:/mnt/cache \
    sourcegraph/searcher:3.2.1

echo "Deployed searcher $1 service"