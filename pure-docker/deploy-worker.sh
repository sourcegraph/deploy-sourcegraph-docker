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
    -e 'OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317' \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -e INDEXED_SEARCH_SERVERS="$(addresses "zoekt-webserver-" $NUM_INDEXED_SEARCH ":6070")" \
    -e SEARCHER_URL="$(addresses "http://searcher-" $NUM_SEARCHER ":3181")" \
    -e SRC_GIT_SERVERS="$(addresses "gitserver-" $NUM_GITSERVER ":3178")" \
    -e SYMBOLS_URL="$(addresses "http://symbols-" $NUM_SYMBOLS ":3184")" \
    -e PRECISE_CODE_INTEL_UPLOAD_BACKEND=blobstore \
    -e PRECISE_CODE_INTEL_UPLOAD_AWS_ENDPOINT=http://blobstore:9000 \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/worker:5.1.5@sha256:2a76db1bd4e433bb26b3c9a07be39077819ed55b7cd1236af65a91556c59c821

echo "Deployed worker service"
