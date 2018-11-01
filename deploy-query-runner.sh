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
    sourcegraph/query-runner:2.12.0@sha256:966a3766394888fdbede584944b032dad86032489637fa15ef0fa84bf120e00b

echo "Deployed query-runner service"