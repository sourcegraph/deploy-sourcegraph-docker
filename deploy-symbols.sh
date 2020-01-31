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
    index.docker.io/sourcegraph/symbols:3.12.5@sha256:cd45dee51865dd7a35ef1596e7f879fcba2ec868a7d85115d287443aaa1a56d7

echo "Deployed symbols $1 service"