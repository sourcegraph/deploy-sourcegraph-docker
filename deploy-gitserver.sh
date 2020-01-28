#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Stores clones of repositories to perform Git operations.
#
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3178/TCP 6060/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=gitserver-$1 \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    -e GOMAXPROCS=4 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e JAEGER_AGENT_HOST='jaeger-agent' \
    -v ~/sourcegraph-docker/gitserver-$1-disk:/data/repos \
    index.docker.io/sourcegraph/gitserver:3.12.3@sha256:46de0ef5d67888ad7c7c883f46f9c537a1e2efd5cc8bc3e1bfda5c37b7ddb0e7

echo "Deployed gitserver $1 service"
