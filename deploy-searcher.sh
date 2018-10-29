#!/usr/bin/env bash
set -e

# Description: Backend for text search operations.
#
# CPU: 2
# Memory: 2GB
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://searcher:3181/healthz
# Ports exposed to other Sourcegraph services: 3181/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=searcher \
    --network=sourcegraph \
    -e SEARCHER_CACHE_SIZE_MB=100000 \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e POD_NAME=searcher \
    -e CACHE_DIR=/mnt/cache/searcher \
    -v ~/sourcegraph-docker/searcher-disk:/mnt/cache \
    sourcegraph/searcher:2.12.0@sha256:7b7370fb39d8969d46f747f13447cef4a641ed1d21fd5a54583c383ae0462ecc

echo "Deployed searcher service"