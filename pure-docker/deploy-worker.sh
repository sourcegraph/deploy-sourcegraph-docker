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
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -e INDEXED_SEARCH_SERVERS="$(addresses "zoekt-webserver-" $NUM_INDEXED_SEARCH ":6070")" \
    -e SEARCHER_URL="$(addresses "http://searcher-" $NUM_SEARCHER ":3181")" \
    -e SRC_GIT_SERVERS="$(addresses "gitserver-" $NUM_GITSERVER ":3178")" \
    -e SYMBOLS_URL="$(addresses "http://symbols-" $NUM_SYMBOLS ":3184")" \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/worker:3.42.1@sha256:fd77bfde217842d3cfaf92867d63e5f1476deaec5a666aef6e639fce2cb6b015

echo "Deployed worker service"
