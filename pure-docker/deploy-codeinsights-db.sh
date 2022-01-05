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
    index.docker.io/sourcegraph/codeinsights-db:3.35.1@sha256:aca7e3122d4528fb33e7cf613f8fe19828cedbd7ca66d8e35215dd4626636101

# Note: You should deploy this as a container, do not try to connect it to your external
# Postgres deployment (TimescaleDB is a bit special and most hosted Postgres deployments
# do not support TimescaleDB, the data here is akin to gitserver's data, where losing it
# would be bad but it can be rebuilt given enough time.)

echo "Deployed codeinsights-db service"
