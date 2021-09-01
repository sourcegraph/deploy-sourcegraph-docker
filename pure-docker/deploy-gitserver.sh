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
    -e JAEGER_AGENT_HOST=jaeger \
    -v $VOLUME:/data/repos \
    index.docker.io/sourcegraph/gitserver:3.31.1@sha256:53d9ec7ac7e1cc75c6e999f2f412e70683c02ac5b26ca9db80b07a58cde32bf2

echo "Deployed gitserver $1 service"
