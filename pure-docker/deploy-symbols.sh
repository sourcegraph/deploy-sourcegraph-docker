#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for symbols operations.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: none
# Ports exposed to other Sourcegraph services: 3184/TCP 6060/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/symbols-$1-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=symbols-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=4g \
    -e GOMAXPROCS=2 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e 'OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317' \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/symbols:5.3.0@sha256:07c7c5ea96c38c7b2c276411373a2dd69171a00e3e44447886bec5a8ca7d52eb

echo "Deployed symbols $1 service"
