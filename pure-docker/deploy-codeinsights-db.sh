#!/usr/bin/env bash
set -e

# Description: PostgreSQL database for code insights data.
#
# Disk: 128GB / persistent SSD
# Network: 1Gbps
# Liveness probe: 5432/TCP
# Ports exposed to other Sourcegraph services: 5432/TCP 9187/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/codeinsights-db-disk"
./ensure-volume.sh $VOLUME 999

# Remove timescaledb from the shared_preload_libraries configuration
# This step can be performed manually instead of run as part of the deploy script
sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'timescaledb(.*)\'/\1 = '\2'/;s/,'/'/" $VOLUME/pgdata/postgresql.conf

docker run --detach \
    --name=codeinsights-db \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=2g \
    -e POSTGRES_DB=postgres \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_USER=postgres \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v $VOLUME:/var/lib/postgresql/data/ \
    index.docker.io/sourcegraph/codeinsights-db:3.41.0@sha256:572a1a59b067c529393de7297201f3e4e0b94c2fb590efe26918d39c2af2f6fd

# Sourcegraph requires PostgreSQL 12+. Generally newer versions are better,
# but anything 12 and higher is supported.

echo "Deployed codeinsights-db service"
