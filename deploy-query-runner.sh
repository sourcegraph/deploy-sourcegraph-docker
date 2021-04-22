#!/usr/bin/env bash
set -e

# Description: Saved search query runner / notification service.
#
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3183/TCP 6060/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=query-runner \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    -e GOMAXPROCS=1 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST=jaeger \
    index.docker.io/sourcegraph/query-runner:3.27.1@sha256:e01ae3472af9f81be211f56fccbd22c2b8a84d15d8d29f7aa206172994876672

echo "Deployed query-runner service"
