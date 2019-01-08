#!/usr/bin/env bash
set -e

# Description: Backend for symbols operations.
#
# CPU: 2
# Memory: 2GB
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: none
# Ports exposed to other Sourcegraph services: 3184/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=symbols-0 \
    --network=sourcegraph \
    --restart=always \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/symbols-disk:/mnt/cache \
    sourcegraph/symbols:3.0.0-alpha.8

echo "Deployed symbols service"