#!/usr/bin/env bash
set -e

# Description: Backend for syntax highlighting operations.
#
# CPU: 2
# Memory: 512MB
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
    sourcegraph/syntect_server:d74791c@sha256:613a1dcc099a712e5cedddb9cfba3bdd5b1e625982be7f86a49e530027676038

echo "Deployed syntect-server service"