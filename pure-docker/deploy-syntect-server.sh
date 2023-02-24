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
    index.docker.io/sourcegraph/syntax-highlighter:4.5.1@sha256:19f3cacf354c23f5a7f9c989958adb0683c5993a914870596bd4c30023a5ae7e

echo "Deployed syntect-server service"
