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
    index.docker.io/sourcegraph/query-runner:3.34.1@sha256:f25ff41178d3ab9013c400ceb10d2612932c019bcbaa6c87e82f6b2aa730e247

echo "Deployed query-runner service"
