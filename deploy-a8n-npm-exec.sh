#!/usr/bin/env bash
set -e

# Description: Runs npm commands for automation campaigns.
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
#     { "from": "/.api/extension-containers/a8n-npm-exec", "to": "http://a8n-npm-exec:5152" },
#   ],
#
docker run --detach \
       --name=a8n-npm-exec \
       --network=sourcegraph \
       --restart=always \
       --cpus=4 \
       --memory=4g \
	   --env PORT=5152 \
       sourcegraph/a8n-npm-exec:npm6.9.0@sha256:768d31025acb4536492060531be40afe35aca9d2526c559cc589562d84b330af

echo "Deployed a8n-npm-exec service"
