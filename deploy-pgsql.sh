#!/usr/bin/env bash
set -e

# Description: PostgreSQL database for various data.
#
# CPU: 2
# Memory: 1GB
# Disk: 128GB / persistent SSD
# Network: 100mbps
# Liveness probe: 5432/TCP
# Ports exposed to other Sourcegraph services: 5432/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=pgsql \
    --network=sourcegraph \
    --restart=always \
    -e PGDATA=/data/pgdata \
    -e POSTGRES_USER=sg \
    -v ~/sourcegraph-docker/pgsql-disk:/data/pgdata \
    sourcegraph/postgres:9.4@sha256:eccea696a68cf9c7ff668398e80ecfadcac990d5f0b9aef15a107aa94128b632

echo "Deployed pgsql service"