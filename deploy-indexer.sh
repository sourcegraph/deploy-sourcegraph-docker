#!/usr/bin/env bash
set -e

# Description: Asynchronous indexing for global references.
#
# CPU: 1
# Memory: 1GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3179/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=indexer \
    --network=sourcegraph \
    --restart=always \
    -e LSP_PROXY=lsp-proxy:4388 \
    -e PGDATABASE=sg \
    -e PGHOST=pgsql \
    -e PGPORT=5432 \
    -e PGSSLMODE=disable \
    -e PGUSER=sg \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    sourcegraph/indexer:2.12.0@sha256:69232170b551fe438cfef619c02c1b679c43365411518e19f279930586d07027

echo "Deployed indexer service"