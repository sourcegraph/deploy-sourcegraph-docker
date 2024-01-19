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
    us-central1-docker.pkg.dev/sourcegraph-ci/rfc795-internal/syntax-highlighter:5.3.666@sha256:860a653cdaca532d6d3dfce006753d655d3d5aa681eded10ed6e10ff1b56ee14

echo "Deployed syntect-server service"
