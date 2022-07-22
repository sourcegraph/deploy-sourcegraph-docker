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
    index.docker.io/sourcegraph/migrator:3.42.0@sha256:a4c2000ad634d1e4abb8a983c9cdff49cc45a0b33dea5ce3da1455300440dc17 \
    up -db=all

echo "Deployed migrator service"
