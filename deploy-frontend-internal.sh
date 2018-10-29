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
    -e LSP_PROXY=lsp-proxy:4388 \
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
    sourcegraph/frontend:2.12.0@sha256:8a766780718fea828f7360d92f7077b0bb342253611edebb37b7ae8688c38fdc \
    serve # command

# Create /etc/sourcegraph/config.json
docker cp ./sourcegraph sourcegraph-frontend-internal:/etc/

docker start sourcegraph-frontend-internal
echo "Deployed sourcegraph-frontend-internal service"