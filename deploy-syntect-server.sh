#!/usr/bin/env bash
set -e

# Description: Backend for syntax highlighting operations.
#
# Disk: none
# Network: 100mbps
# Liveness probe: HTTP GET http://syntect-server:9238/health
# Ports exposed to other Sourcegraph services: 9238/TCP 6060/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=syntect-server \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=6g \
    sourcegraph/syntect_server:cacdc21@sha256:75dedb05589b3b6d3c3f15f86e5c35172f1c0460e71633ef95b9d4c294b51b4f

echo "Deployed syntect-server service"
