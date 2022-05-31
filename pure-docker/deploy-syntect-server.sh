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
    index.docker.io/sourcegraph/syntax-highlighter:3.40.1@sha256:e4e1835ed91ded3e0e396b531a1de3dcf743069d3665d234049e4491b0cec881

echo "Deployed syntect-server service"
