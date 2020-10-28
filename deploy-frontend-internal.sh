#!/usr/bin/env bash
set -e
source ./replicas.sh

# Description: Serves the internal Sourcegraph frontend API.
#
# Disk: 128GB / non-persistent SSD
# Network: 100mbps
# Liveness probe: n/a
# Ports exposed to other Sourcegraph services: 3090/TCP 6060/TCP
# Ports exposed to the public internet: none
#
VOLUME="$HOME/sourcegraph-docker/sourcegraph-frontend-internal-0-disk"
./ensure-volume.sh $VOLUME 100
docker run --detach \
    --name=sourcegraph-frontend-internal \
    --network=sourcegraph \
    --restart=always \
    --cpus=4 \
    --memory=8g \
    -e DEPLOY_TYPE=pure-docker \
    -e GOMAXPROCS=4 \
    -e PGHOST=pgsql \
    -e CODEINTEL_PGHOST=codeintel-db \
    -e SRC_GIT_SERVERS="$(addresses "gitserver-" $NUM_GITSERVER ":3178")" \
    -e SRC_SYNTECT_SERVER=http://syntect-server:9238 \
    -e SEARCHER_URL="$(addresses "http://searcher-" $NUM_SEARCHER ":3181")" \
    -e SYMBOLS_URL="$(addresses "http://symbols-" $NUM_SYMBOLS ":3184")" \
    -e INDEXED_SEARCH_SERVERS="$(addresses "zoekt-webserver-" $NUM_INDEXED_SEARCH ":6070")" \
    -e SRC_FRONTEND_INTERNAL=sourcegraph-frontend-internal:3090 \
    -e REPO_UPDATER_URL=http://repo-updater:3182 \
    -e PRECISE_CODE_INTEL_BUNDLE_MANAGER_URL=http://precise-code-intel-bundle-manager:3187 \
    -e GRAFANA_SERVER_URL=http://grafana:3000 \
    -e JAEGER_SERVER_URL=http://jaeger:16686 \
    -e GITHUB_BASE_URL=http://github-proxy:3180 \
    -e PROMETHEUS_URL=http://prometheus:9090 \
    # If these variables are updated, they must also be updated in the
    # deploy-frontend and precise-code-intel-worker containers as well.
	-e PRECISE_CODE_INTEL_UPLOAD_BACKEND=S3 \
	-e PRECISE_CODE_INTEL_UPLOAD_BUCKET=lsif-uploads \
	-e PRECISE_CODE_INTEL_UPLOAD_MANAGE_BUCKET=true \
	-e AWS_ACCESS_KEY_ID='AKIAIOSFODNN7EXAMPLE' \
	-e AWS_SECRET_ACCESS_KEY='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' \
	-e AWS_ENDPOINT=http://minio:9000 \
	-e AWS_REGION=us-east-1 \
	-e AWS_S3_FORCE_PATH_STYLE=true \
    -v $VOLUME:/mnt/cache \
    index.docker.io/sourcegraph/frontend:3.21.2@sha256:0b11ad9197debc409c77f057d4d2b72147d5d2044c40ac16296c68d3ed1e21d3

echo "Deployed sourcegraph-frontend-internal service"
