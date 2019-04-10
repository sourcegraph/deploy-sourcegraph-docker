#!/usr/bin/env bash
set -e

# Description: PostgreSQL database for various data.
#
# Disk: 128GB / persistent SSD
# Network: 100mbps
# Liveness probe: 5432/TCP
# Ports exposed to other Sourcegraph services: 5432/TCP 9187/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=pgsql \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=1g \
    -v ~/sourcegraph-docker/pgsql-disk:/data/pgdata \
    sourcegraph/postgres:18-11-26_9.4_a9463ecc@sha256:ca9964a200beb9756704279f82f13caea39eaee8ee9e9e13eba57f2de4952f71

echo "Deployed pgsql service"