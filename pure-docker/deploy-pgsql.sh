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
    index.docker.io/sourcegraph/postgres-12-alpine:135107_2022-03-03_9498a8bd3366@sha256:e26b159dc7c0c47d136886390c899816e669a3c2c1ead689bdad0b610364e45e

# Sourcegraph requires PostgreSQL 12+. Generally newer versions are better,
# but anything 12 and higher is supported.

echo "Deployed pgsql service"
