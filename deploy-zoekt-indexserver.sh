#!/usr/bin/env bash
set -e

# Description: Backend for indexed text search operations.
#
# CPU: 4
# Memory: 4GB
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 6072/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=zoekt-indexserver \
    --network=sourcegraph \
    --privileged \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    sourcegraph/zoekt:18-09-14_2f4b0f2@sha256:c51363fc9c8ad8fee2909593bb37475afb04f5ddb5fa67a580b260ab7abcd377 \
    zoekt-sourcegraph-indexserver -index /data/index -sourcegraph_url http://sourcegraph-frontend-internal:3090 -listen :6072 -interval 1m -cpu_fraction "1.0" # command

echo "Deployed zoekt-indexserver service"