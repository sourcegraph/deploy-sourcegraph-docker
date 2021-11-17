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
    index.docker.io/sourcegraph/worker:3.33.1@sha256:3acd9f22673be6295fd225525fc864ccc324cc05c4b568745e481a930e041e3e

echo "Deployed worker service"
