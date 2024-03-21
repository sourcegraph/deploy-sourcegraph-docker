#!/usr/bin/env bash
set -e

# Description: Performs database migrations
#
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: none
# Ports exposed to the public internet: none
#

docker run --detach \
    --name=migrator \
    --network=sourcegraph \
    --restart=on-failure \
    --cpus=1 \
    --memory=1g \
    -e PGHOST=pgsql \
    -e PGUSER=sg \
    -e CODEINTEL_PGUSER=sg \
    -e CODEINTEL_PGHOST=codeintel-db \
    -e CODEINSIGHTS_PGDATASOURCE=postgres://postgres:password@codeinsights-db:5432/postgres \
    index.docker.io/sourcegraph/migrator:5.3.3@sha256:13f062895d5a5a7fdafb656140d8b732c1451fc71bd1808c1653df8bb9ca1e61 \
    up -db=all

echo "Deployed migrator service"
