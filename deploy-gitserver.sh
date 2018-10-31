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
docker run --detach \
    --name=gitserver-0 \
    --network=sourcegraph \
    --restart=always \
    sourcegraph/gitserver:2.12.0@sha256:0fde51ee93b0cdf06ffb0a06ee321f5014b2fe7f9bdc0572dc00bfaaaac4c9b5

echo "Deployed gitserver service"