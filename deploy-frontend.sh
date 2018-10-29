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
    -e PGDATABASE=sg \
    -e PGHOST=pgsql \
    -e PGPORT=5432 \
    -e PGSSLMODE=disable \
    -e PGUSER=sg \
    -e PUBLIC_REPO_REDIRECTS=true \
    -e SRC_GIT_SERVERS=gitserver-0:3178 \
    -e SEARCHER_URL=http://searcher:3181 \
    -e SYMBOLS_URL=http://symbols:3184 \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -p 127.0.0.1:3080:3080 \
    sourcegraph/frontend:2.12.0@sha256:8a766780718fea828f7360d92f7077b0bb342253611edebb37b7ae8688c38fdc \
    serve # command

# For HTTPS instead of HTTP (3080), add the following to 'docker create' above:
# -p 127.0.0.1:3443:3443 \
# -e TLS_CERT=$MY_SECRET_TLS_CERT \
# -e TLS_KEY=$MY_SECRET_TLS_KEY \

# Create /etc/sourcegraph/config.json
docker cp ./sourcegraph sourcegraph-frontend:/etc/

docker start sourcegraph-frontend
echo "Deployed sourcegraph-frontend service"