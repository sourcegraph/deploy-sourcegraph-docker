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
docker run --detach \
    --name=symbols \
    --network=sourcegraph \
    --restart=always \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -v ~/sourcegraph-docker/symbols-disk:/mnt/cache \
    sourcegraph/symbols:2.12.0@sha256:c19c072bdebc21f11393a80322a529e043cf3c41a68e37a1dc119e00fde54a7c

echo "Deployed symbols service"