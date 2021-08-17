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
    index.docker.io/sourcegraph/codeinsights-db:3.30.4@sha256:3d15c3ff24fcd90c7b987a3de40e4708085033b4da5e37923b4c1c3dcd50dbd4

# Note: You should deploy this as a container, do not try to connect it to your external
# Postgres deployment (TimescaleDB is a bit special and most hosted Postgres deployments
# do not support TimescaleDB, the data here is akin to gitserver's data, where losing it
# would be bad but it can be rebuilt given enough time.)

echo "Deployed codeinsights-db service"
