#!/usr/bin/env bash
set -e

# Description: Saved search query runner / notification service.
#
# CPU: 1
# Memory: 1GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3183/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=query-runner \
    --network=sourcegraph \
    --restart=always \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST='jaeger-agent' \
    sourcegraph/query-runner:3.2.0

echo "Deployed query-runner service"