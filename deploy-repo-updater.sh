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
    --cpus=4 \
    --memory=4g \
    -e GOMAXPROCS=1 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST='jaeger-agent' \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -v ~/sourcegraph-docker/repo-updater-disk:/mnt/cache \
    sourcegraph/repo-updater:3.10.2@sha256:dacbcf1ba75f7fcd524adf1eb8abb99c0254f3bbf14a9c9cc0df045c65ab62ef

echo "Deployed repo-updater service"