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
    index.docker.io/sourcegraph/syntax-highlighter:3.33.1@sha256:4506dd532540f12b6532b0616ddd1beef7a110e68e944715a1b1f28412bb7163

echo "Deployed syntect-server service"
