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
    index.docker.io/sourcegraph/github-proxy:3.22.0@sha256:8b19ba2d2dd00187287265cd0afc6b34b5a2881a0cdd2fcb9093233e1614804c

echo "Deployed github-proxy service"
