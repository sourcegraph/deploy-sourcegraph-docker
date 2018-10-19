#!/usr/bin/env bash
set -e

# Description: Multiplexer between frontend and LSP servers.
#
# CPU: 1
# Memory: 8GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: 4388/TCP
# Ports exposed to other Sourcegraph services: 4388/TCP
# Ports exposed to the public internet: none
#
docker create \
    --name=lsp-proxy \
    --network=sourcegraph \
    -e SOURCEGRAPH_CONFIG_FILE=/etc/sourcegraph/config.json \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e POD_NAME=lsp-proxy \
    -e CACHE_DIR=/mnt/cache/lsp-proxy \
    -v ~/sourcegraph-docker/lsp-proxy-disk:/mnt/cache \
    sourcegraph/lsp-proxy:2.12.0@sha256:4cb8aaae7c3568d6780715472523538733ad17bbf53a9a758dd7e34b35025a00

# Create /etc/sourcegraph/config.json
docker cp ./sourcegraph lsp-proxy:/etc/

docker start lsp-proxy
echo "Deployed lsp-proxy service"