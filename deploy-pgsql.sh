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
    sourcegraph/postgres-11.1:19-02-13_22d74790@sha256:10c2ff7a4da422cd75e022b51bef3a0c935f4b3ded335d9679a4f1202db605d2

# Sourcegraph requires PostgreSQL 9.6+. Generally newer versions are better,
# but anything 9.6 and higher is supported.

echo "Deployed pgsql service"