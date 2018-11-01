#!/usr/bin/env bash
set -e

# Description: Serves the internal Sourcegraph frontend API.
#
# CPU: 2
# Memory: 4GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3090
# Ports exposed to the public internet: none
#
docker create \
    --name=sourcegraph-frontend-internal \
    --network=sourcegraph \
    --restart=always \
    -e PGHOST=pgsql \
    # Note: These are space-seperated lists, so you can add more gitservers,
    # searchers, or symbols container instances for scaling purposes.
    #
    # Be sure to apply changes here to both frontend and frontend-internal services.
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e SEARCHER_URL=http://searcher-0:3181 \
    -e SYMBOLS_URL=http://symbols-0:3184 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    sourcegraph/frontend:3.0.0-alpha.2 \
    serve # command

# Create /etc/sourcegraph/config.json
docker cp ./sourcegraph sourcegraph-frontend-internal:/etc/

docker start sourcegraph-frontend-internal
echo "Deployed sourcegraph-frontend-internal service"