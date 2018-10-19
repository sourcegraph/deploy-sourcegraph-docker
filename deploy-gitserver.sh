#!/usr/bin/env bash
set -e

# Description: Stores clones of repositories to perform Git operations.
#
# CPU: 4
# Memory: 8GB
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3182/TCP
# Ports exposed to the public internet: none
#
docker create \
    --name=gitserver-0 \
    --network=sourcegraph \
    -e SOURCEGRAPH_CONFIG_FILE=/etc/sourcegraph/config.json \
    -e SRC_REPOS_DIR=/data/repos \
    sourcegraph/gitserver:2.12.0@sha256:0fde51ee93b0cdf06ffb0a06ee321f5014b2fe7f9bdc0572dc00bfaaaac4c9b5

# Create /etc/sourcegraph/config.json
docker cp ./sourcegraph gitserver-0:/etc/

docker start gitserver-0
echo "Deployed gitserver-0 service"