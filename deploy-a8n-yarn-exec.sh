#!/usr/bin/env bash
set -e

# Description: Runs yarn commands for automation campaigns.
#
# Disk: non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 5151/TCP
# Ports exposed to the public internet: none
#
# To use, add the following entry to Sourcegraph site configuration:
#
#   "extensions.containers": [
#     { "from": "/.api/extension-containers/a8n-yarn-exec", "to": "http://a8n-yarn-exec:5153" },
#   ],
#
docker run --detach \
    --name=a8n-yarn-exec \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=4g \
    -e PORT=5153 \
    sourcegraph/a8n-yarn-exec:yarn1.19.0@sha256:0d2fdded7940973780a9fe9020beedbe6652f541882317ee1c5f7adda27ba712

echo "Deployed a8n-yarn-exec service"
