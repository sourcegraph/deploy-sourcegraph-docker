#!/usr/bin/env bash
set -e

# Description: Stores clones of repositories to perform Git operations.
#
# CPU: 4
# Memory: 8GB
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3182/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=gitserver-0 \
    --network=sourcegraph \
    --restart=always \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    sourcegraph/gitserver:3.0.0-alpha.4

echo "Deployed gitserver service"