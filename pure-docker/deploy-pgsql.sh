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
VOLUME="$HOME/sourcegraph-docker/pgsql-disk"
./ensure-volume.sh $VOLUME 999
docker run --detach \
    --name=pgsql \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=2g \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v $VOLUME:/var/lib/postgresql/data/ \
    index.docker.io/sourcegraph/postgres-12.6:95244_2021-05-06_2c1f77e@sha256:35040317490324a15e1259c9023a726eb27c694530f6f8877e87d337c7b97778

# Sourcegraph requires PostgreSQL 12+. Generally newer versions are better,
# but anything 12 and higher is supported.

echo "Deployed pgsql service"
