#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for symbols operations.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: none
# Ports exposed to other Sourcegraph services: 3184/TCP 6060/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=symbols-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=4g \
    -e GOMAXPROCS=2 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST='jaeger-agent' \
    -v ~/sourcegraph-docker/symbols-$1-disk:/mnt/cache \
    sourcegraph/symbols:3.10.3@sha256:2b74f430c38ec6143773bc834466d790b43c0515e7c9198082bc25f575c352a9

echo "Deployed symbols $1 service"