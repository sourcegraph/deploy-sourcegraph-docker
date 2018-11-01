#!/usr/bin/env bash
set -e

# Description: Serves the frontend of Sourcegraph via HTTP(S).
#
# CPU: 2
# Memory: 4GB
# Disk: 1GB / non-persistent SSD (only for read-only config file)
# Network: 100mbps
# Liveness probe: HTTP GET http://sourcegraph-frontend:3080/healthz
# Ports exposed to other Sourcegraph services: none
# Ports exposed to the public internet: 3080 (HTTP) and/or 3443 (HTTPS)
#
docker create \
    --name=sourcegraph-frontend \
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
    -p 127.0.0.1:3080:3080 \
    sourcegraph/frontend:3.0.0-alpha.2 \
    serve # command

# For HTTPS instead of HTTP (3080), add the following to 'docker create' above:
# -p 127.0.0.1:3443:3443 \
# -e TLS_CERT=$MY_SECRET_TLS_CERT \
# -e TLS_KEY=$MY_SECRET_TLS_KEY \

# Create /etc/sourcegraph/config.json
docker cp ./sourcegraph sourcegraph-frontend:/etc/

docker start sourcegraph-frontend
echo "Deployed sourcegraph-frontend service"