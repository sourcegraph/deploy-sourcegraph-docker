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
    -v $VOLUME:/data/ \
    index.docker.io/sourcegraph/postgres-11.4:insiders@sha256:072481559d559cfd9a53ad77c3688b5cf583117457fd452ae238a20405923297

# Sourcegraph requires PostgreSQL 9.6+. Generally newer versions are better,
# but anything 9.6 and higher is supported.

echo "Deployed pgsql service"
