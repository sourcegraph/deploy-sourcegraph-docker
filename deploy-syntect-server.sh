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
    sourcegraph/syntect_server:3afd1c9@sha256:fc1e394ca450130cc4e73c2e8c2303fb15ed67116a4c4fc92b516cbc00bf8d8f

echo "Deployed syntect-server service"
