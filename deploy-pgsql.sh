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
    index.docker.io/sourcegraph/postgres-11.4:3.17.2@sha256:63090799b34b3115a387d96fe2227a37999d432b774a1d9b7966b8c5d81b56ad

# Sourcegraph requires PostgreSQL 9.6+. Generally newer versions are better,
# but anything 9.6 and higher is supported.

echo "Deployed pgsql service"
