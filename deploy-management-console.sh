#!/usr/bin/env bash
set -e

# Description: Serves the frontend of Sourcegraph via HTTP(S).
#
# CPU: 1
# Memory: 512MB
# Disk: 1GB / persistent (can be discarded, only contains self-signed TLS cert)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: none
# Ports exposed to the public internet: 2633 (HTTPS); optionally behind a firewall for extra security
#
docker run --detach \
    --name=management-console \
    --network=sourcegraph \
    --restart=always \
    -v ~/sourcegraph-docker/management-console-disk:/etc/sourcegraph \
    -e PGHOST=pgsql \
    -p 127.0.0.1:2633:2633 \
    sourcegraph/management-console:3.0.0-alpha.6

echo "Deployed management-console service"