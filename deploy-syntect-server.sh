#!/usr/bin/env bash
set -e

# Description: Backend for syntax highlighting operations.
#
# CPU: 2
# Memory: 512MB
# Disk: none
# Network: 100mbps
# Liveness probe: HTTP GET http://syntect-server:9238/health
# Ports exposed to other Sourcegraph services: 9238/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=syntect-server \
    --network=sourcegraph \
    --restart=always \
    sourcegraph/syntect_server:393a538@sha256:8e689829d2e3e774c811efc89524238e4c1957e52756ba8cc3c07c1fb3a81cb6

echo "Deployed syntect-server service"