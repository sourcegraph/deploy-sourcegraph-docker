#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Handles repository metadata (not Git data) lookups and updates from external code hosts and other similar services.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3182/TCP 6060/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=repo-updater \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=512m \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST='jaeger-agent' \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -v ~/sourcegraph-docker/repo-updater-disk:/mnt/cache \
    sourcegraph/repo-updater:3.3.0

echo "Deployed repo-updater service"