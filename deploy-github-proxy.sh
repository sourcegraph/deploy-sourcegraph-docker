#!/usr/bin/env bash
set -e

# Description: Rate-limiting proxy for the GitHub API.
#
# CPU: 1
# Memory: 1GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3180/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=github-proxy \
    --network=sourcegraph \
    --restart=always \
    sourcegraph/github-proxy:2.12.0@sha256:9f02da855dc5bef22d367033a5d28c1c19bb573b1eb048195684dda5cacc45dd

echo "Deployed github-proxy service"