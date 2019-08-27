#!/usr/bin/env bash
set -e

# Description: Serves the frontend of Sourcegraph via HTTP(S).
#
# Disk: 1GB / persistent (can be discarded, only contains self-signed TLS cert)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 6060/TCP
# Ports exposed to the public internet: 2633 (HTTPS); optionally behind a firewall for extra security
#
docker run --detach \
    --name=management-console \
    --network=sourcegraph \
    --restart=always \
    --cpus=1 \
    --memory=512m \
    -e GOMAXPROCS=1 \
    -v ~/sourcegraph-docker/management-console-disk:/etc/sourcegraph \
    -e PGHOST=pgsql \
    -p 0.0.0.0:2633:2633 \
    sourcegraph/management-console:3.6.2

echo "Deployed management-console service"