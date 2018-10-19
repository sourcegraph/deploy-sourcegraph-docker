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
    sourcegraph/syntect_server:624a1a2@sha256:46c1c2ffa6d804687c3d921716504ee2f6655cf02e2f4b4b97893c3d85e53e81

echo "Deployed syntect-server service"