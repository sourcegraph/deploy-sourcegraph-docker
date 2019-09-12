#!/usr/bin/env bash
set -e

# Description: Backend for syntax highlighting operations.
#
# Disk: none
# Network: 100mbps
# Liveness probe: HTTP GET http://syntect-server:9238/health
# Ports exposed to other Sourcegraph services: 9238/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=syntect-server \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=4g \
    sourcegraph/syntect_server:5e1efbb@sha256:6ec136246b302a6c8fc113f087a66d5f9a89a9f5b851e9abb917c8b5e1d8c4b1

echo "Deployed syntect-server service"