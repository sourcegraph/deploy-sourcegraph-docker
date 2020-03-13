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
    -e JAEGER_AGENT_HOST='jaeger-agent' \
    index.docker.io/sourcegraph/query-runner:3.13.2@sha256:8a714e4d88545ed0f9330e5c2b07fcfc7d60b102656509054bba8bba2ea9d53a

echo "Deployed query-runner service"