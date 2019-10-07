#!/usr/bin/env bash
set -e

# Description: Runs Ruby bundler commands in repository checkouts for automation campaigns.
#
# Disk: non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 5151/TCP
# Ports exposed to the public internet: none
#
docker run --detach \
    --name=a8n-ruby-bundler-exec \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=4g \
	--env PORT=5151 \
    sourcegraph/a8n-ruby-bundler-exec:ruby2.6.4@sha256:b15148d531b7e00164041c234dbaa7314ad5ece2042bd9e1cc78227be6c62adb

echo "Deployed a8n-ruby-bundler-exec service"
