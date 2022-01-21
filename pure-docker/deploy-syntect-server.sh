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
    index.docker.io/sourcegraph/syntax-highlighter:3.36.0@sha256:b5814d6dd78b81d61c6477537c3f7839296e23344a7143486d48635ac6bb5ee5

echo "Deployed syntect-server service"
