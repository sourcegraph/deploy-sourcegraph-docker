#!/usr/bin/env bash
set -e

# Description: TimescaleDB time-series database for code insights data.
#
# Disk: 128GB / persistent SSD
# Network: 1Gbps
# Liveness probe: 5432/TCP
# Ports exposed to other Sourcegraph services: 5432/TCP 9187/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/codeinsights-db-disk"
./ensure-volume.sh $VOLUME 999
docker run --detach \
    --name=codeinsights-db \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=2g \
    -e POSTGRES_PASSWORD=password \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v $VOLUME:/var/lib/postgresql/data/ \
    index.docker.io/sourcegraph/codeinsights-db:3.35.0@sha256:8c536aae533788c61d520fbaa77fd3d49d44e89acaced9561e9bbe531223380f

# Note: You should deploy this as a container, do not try to connect it to your external
# Postgres deployment (TimescaleDB is a bit special and most hosted Postgres deployments
# do not support TimescaleDB, the data here is akin to gitserver's data, where losing it
# would be bad but it can be rebuilt given enough time.)

echo "Deployed codeinsights-db service"
