#!/usr/bin/env bash
set -e

# Description: Rate-limiting proxy for the GitHub API.
#
# CPU: 1
# Memory: 1GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3180/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=github-proxy \
    --network=sourcegraph \
    --restart=always \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    sourcegraph/github-proxy:3.0.1

echo "Deployed github-proxy service"