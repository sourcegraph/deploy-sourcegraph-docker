#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Handles repository metadata (not Git data) lookups and updates from external code hosts and other similar services.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3182/TCP 6060/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/repo-updater-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=repo-updater \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=4g \
    -e GOMAXPROCS=1 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e 'OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317' \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/repo-updater:5.2.1@sha256:3e0b6b4ef13af5c4d335bf9e66db136b4a4cde63ab5e6036dec9afe84280cf63

echo "Deployed repo-updater service"
