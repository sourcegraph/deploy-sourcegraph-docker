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
    index.docker.io/sourcegraph/migrator:5.0.2@sha256:7099095e9b87dcc570c403ef92258b70eff0308cb8474e37911df4f37a89a5c4 \
    up -db=all

echo "Deployed migrator service"
