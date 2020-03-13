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
docker run --detach \
    --name=replacer \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=512m \
    -e GOMAXPROCS=1 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -v ~/sourcegraph-docker/replacer-disk:/mnt/cache \
    index.docker.io/sourcegraph/replacer:3.13.2@sha256:4bffbb9af71d742edc8ae1a4e1aaa9395f70816df0e2b076bd324fde483967f3

echo "Deployed replacer service"