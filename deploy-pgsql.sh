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
    -v ~/sourcegraph-docker/pgsql-disk:/data/pgdata \
    sourcegraph/postgres:18-10-30_9.4_23cea01a@sha256:1eb62bcd0bee6038e1621f12cf26e4f5ca433f225a002fb615c81fd5ddbf8184

echo "Deployed pgsql service"