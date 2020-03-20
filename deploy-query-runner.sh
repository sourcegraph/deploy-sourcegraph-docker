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
    index.docker.io/sourcegraph/query-runner:3.14.0@sha256:1c1e2799d2679e278c16daff1a7160497fa8922fce16b9e27a7bf278455d4aba

echo "Deployed query-runner service"