#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Backend for replace operations.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: GET http://replacer:3185/healthz
# Ports exposed to other Sourcegraph services: 3185/TCP 6060/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/replacer-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=replacer \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=512m \
    -e GOMAXPROCS=1 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/replacer:3.18.0@sha256:bc9652f578c93b6602d109844602ef36d9460e8c9612c417f5298e839380cbc8

echo "Deployed replacer service"
