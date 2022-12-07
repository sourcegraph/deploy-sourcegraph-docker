#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for text search operations.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://searcher:3181/healthz
# Ports exposed to other Sourcegraph services: 3181/TCP 6060/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/searcher-$1-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=searcher-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=2 \
    --memory=2g \
    -e GOMAXPROCS=2 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e 'OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317' \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/searcher:4.2_187939_2022-12-07_5d744edd0103@sha256:79dbed2522f5a512f420e5412a5c35fd24389528090fe368753799acb467b7af

echo "Deployed searcher $1 service"
