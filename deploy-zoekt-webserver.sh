#!/usr/bin/env bash
set -e

# Description: Backend for indexed text search operations.
#
# CPU: 2
# Memory: 4GB
# Disk: 200GB / persistent SSD
# Network: 100mbps
# Liveness probe: HTTP GET http://zoekt-webserver:6070/healthz
# Ports exposed to other Sourcegraph services: 6070/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=zoekt-webserver \
    --network=sourcegraph \
    --restart=always \
    sourcegraph/zoekt:18-09-14_2f4b0f2@sha256:c51363fc9c8ad8fee2909593bb37475afb04f5ddb5fa67a580b260ab7abcd377 \
    zoekt-webserver -index /data/index -pprof -rpc # command

echo "Deployed zoekt-webserver service"