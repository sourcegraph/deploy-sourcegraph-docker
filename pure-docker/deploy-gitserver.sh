#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Stores clones of repositories to perform Git operations.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3178/TCP 6060/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/gitserver-$1-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=gitserver-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    --hostname=gitserver-$1 \
    -e GOMAXPROCS=4 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e 'OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317' \
    -e 'GITHUB_BASE_URL=http://github-proxy:3180' \
    -v $VOLUME:/data/repos \
    index.docker.io/sourcegraph/gitserver:4.3.1@sha256:4d5e977c2de948589a9ae72da40c8e4c75cbae880d55e5f0e9e5bbce343d706a

echo "Deployed gitserver $1 service"
