#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Rate-limiting proxy for the GitHub API.
#
# CPU: 1
# Memory: 1GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3180/TCP 6060/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=github-proxy \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=1g \
    -e GOMAXPROCS=1 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST=jaeger \
    index.docker.io/sourcegraph/github-proxy:3.32.0@sha256:70d12682fe549f9f9da8ccc6465ea53d3889f41b86793e197abb9b4d8584f019

echo "Deployed github-proxy service"
