#!/usr/bin/env bash
set -e

# Description: Backend for symbols operations.
#
# CPU: 2
# Memory: 2GB
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: none
# Ports exposed to other Sourcegraph services: 3184/TCP
# Ports exposed to the public internet: none
#
docker create \
    --name=symbols \
    --network=sourcegraph \
    --expose=3184 \
    -e SOURCEGRAPH_CONFIG_FILE=/etc/sourcegraph/config.json \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e SYMBOLS_CACHE_SIZE_MB=100000 \
    -e POD_NAME=symbols \
    -e CACHE_DIR=/mnt/cache/symbols \
    -v ~/sourcegraph-docker/symbols-disk:/mnt/cache \
    sourcegraph/symbols:2.12.0@sha256:c19c072bdebc21f11393a80322a529e043cf3c41a68e37a1dc119e00fde54a7c

# Create /etc/sourcegraph/config.json
docker cp ./sourcegraph symbols:/etc/

docker start symbols
echo "Deployed symbols service"