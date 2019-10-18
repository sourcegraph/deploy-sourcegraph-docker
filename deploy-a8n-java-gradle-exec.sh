#!/usr/bin/env bash
set -e

# Description: Runs Java/Gradle commands for automation campaigns.
#
# Disk: non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 5154/TCP
# Ports exposed to the public internet: none
#
# To use, add the following entry to Sourcegraph site configuration:
#
#   "extensions.containers": [
#     { "from": "/.api/extension-containers/a8n-java-gradle-exec", "to": "http://a8n-java-gradle-exec:5153" },
#   ],
#
docker run --detach \
       --name=a8n-java-gradle-exec \
       --network=sourcegraph \
       --restart=always \
       --cpus=4 \
       --memory=4g \
       -e PORT=5154 \
       sourcegraph/a8n-java-gradle-exec:openjdk8-gradle4.8.1@sha256:56e2e0a8b91b40b524fbf0233cee8e7390a7a20ae82c071f3c477e6644b54872

echo "Deployed a8n-java-gradle-exec service"
