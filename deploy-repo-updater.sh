#!/usr/bin/env bash
set -e

# Description: Handles repository metadata (not Git data) lookups and updates from external code hosts and other similar services.
#
# CPU: 1
# Memory: 512MB
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3182/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=repo-updater \
    --network=sourcegraph \
    --restart=always \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -v ~/sourcegraph-docker/repo-updater-disk:/mnt/cache \
    sourcegraph/repo-updater:3.0.0-alpha.8

echo "Deployed repo-updater service"