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
    us-central1-docker.pkg.dev/sourcegraph-ci/rfc795-internal/codeinsights-db:5.3.666@sha256:c4a1bd3908658e1c09558a638e378e5570d5f669d27f9f867eeda25fe60cb88f

# Sourcegraph requires PostgreSQL 12+. Generally newer versions are better,
# but anything 12 and higher is supported.

echo "Deployed codeinsights-db service"
