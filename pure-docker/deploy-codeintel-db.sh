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
    index.docker.io/sourcegraph/codeintel-db:5.2.1@sha256:01ce4a6813dabffd02c13eb4c8c5d6e09f425783eed29a85aedbdcdfed6c799c

# Sourcegraph requires PostgreSQL 12+. Generally newer versions are better,
# but anything 12 and higher is supported.

echo "Deployed codeintel-db service"
