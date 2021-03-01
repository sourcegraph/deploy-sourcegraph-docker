#!/usr/bin/env bash
set -e

# Description: PostgreSQL database for code intelligence data.
#
# Disk: 128GB / persistent SSD
# Network: 1Gbps
# Liveness probe: 5432/TCP
# Ports exposed to other Sourcegraph services: 5432/TCP 9187/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/codeintel-db-disk"
./ensure-volume.sh $VOLUME 999
docker run --detach \
    --name=codeintel-db \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=2g \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v $VOLUME:/var/lib/postgresql/data/ \
    index.docker.io/sourcegraph/codeintel-db:3.25.2@sha256:a55fea6638d478c2368c227d06a1a2b7a2056b693967628427d41c92d9209e97

# Sourcegraph requires PostgreSQL 9.6+. Generally newer versions are better,
# but anything 9.6 and higher is supported.

echo "Deployed codeintel-db service"
