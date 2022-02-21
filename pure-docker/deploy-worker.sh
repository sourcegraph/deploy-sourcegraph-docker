#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Manages background processes.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3189/TCP 6060/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/worker-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=worker \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=4g \
    -e GOMAXPROCS=1 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST=jaeger \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/worker:3.37.0@sha256:0b3a8d3a59a65c5aabfa4c5bb78cc6eea1c7926fa66ae7558e20f8ca6b11d629

echo "Deployed worker service"
