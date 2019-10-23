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
    --cpus=4 \
    --memory=2g \
    -v ~/sourcegraph-docker/pgsql-disk:/data/pgdata \
    sourcegraph/postgres-11.4:19-07-15_63c77a05@sha256:21881633991e9548319fcf5b9e2777ddba6404b7d551dedde9e39e5b9287a982

# Sourcegraph requires PostgreSQL 9.6+. Generally newer versions are better,
# but anything 9.6 and higher is supported.

echo "Deployed pgsql service"
