#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for indexed text search operations.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://zoekt-webserver-$1:6070/healthz
# Ports exposed to other Sourcegraph services: 6070/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/zoekt-$1-shared-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=zoekt-webserver-$1 \
    --hostname=zoekt-webserver-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=16 \
    --memory=100g \
    -e GOMAXPROCS=16 \
    -e HOSTNAME=zoekt-webserver-$1:6070 \
    -e 'OPENTELEMETRY_DISABLED=false' \
    -e 'OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317' \
    -v $VOLUME:/data/index \
    index.docker.io/sourcegraph/indexed-searcher:5.2.0@sha256:5c27865112223ad5a6bcf1942202bf2c66ad7c1196d649b6d98806d13a4d6329

echo "Deployed zoekt-webserver $1 service"
