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
    index.docker.io/sourcegraph/migrator:5.1.4@sha256:b871f4d32dee8ae757e3a66e5e0b75b0f2d6e04d6c598f1f0540a8e93648715b \
    up -db=all

echo "Deployed migrator service"
