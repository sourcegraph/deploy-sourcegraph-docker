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
    --memory=512m \
    sourcegraph/syntect_server:056c730@sha256:2f7489ebddfbbe92bef3e72af3840d24f45d387baa0da1edabf06fa732195ae6

echo "Deployed syntect-server service"