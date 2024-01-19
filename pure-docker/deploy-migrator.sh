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
    us-central1-docker.pkg.dev/sourcegraph-ci/rfc795-internal/migrator:5.3.666@sha256:0d908daa0ed40fcc00cd5b64266980c63470b76602f88df10224fa2ffb31398d \
    up -db=all

echo "Deployed migrator service"
