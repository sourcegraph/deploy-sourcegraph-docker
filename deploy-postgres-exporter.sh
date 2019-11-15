#!/usr/bin/env bash
set -e

# Description: Export Prometheus metrics from associated Postgres instance
#
# Disk: none
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services (Prometheus target): 9187/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=postgres-exporter \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    -e DATA_SOURCE_NAME="postgresql://sourcegraph:sourcegraphd@pgsql:5432/postgres?sslmode=disable" \
    wrouesnel/postgres_exporter:v0.7.0@sha256:785c919627c06f540d515aac88b7966f352403f73e931e70dc2cbf783146a98b

echo "Deployed postgres-exporter service"
