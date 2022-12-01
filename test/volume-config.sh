#!/bin/bash

# Create volume directories.
cd /deploy-sourcegraph-docker
echo
echo "creating deployment for volume directories"
echo
./pure-docker/deploy.sh
echo
echo "tearing down deployment for volume directories"
echo
./pure-docker/teardown.sh
# Set permissions on volume directories.
#
# IMPORTANT: If these change, or a new service is introduced, it must be explicitly called out in
# https://docs.sourcegraph.com/admin/updates/pure_docker similar to https://docs.sourcegraph.com/admin/updates/pure_docker#v3-12-5-v3-13-2-changes
echo
echo "forcing static permissions on volume directories"
echo
pushd ~/sourcegraph-docker
chown -R 100:101 gitserver* prometheus-v2* worker* repo-updater* searcher* sourcegraph-frontend* symbols* zoekt* blobstore-disk
chown -R 999:1000 redis-store-disk redis-cache-disk
chown -R 472:472 grafana-disk
chown -R 999:999 pgsql-disk codeintel-db-disk
chown -R 70:70 codeinsights-db-disk
popd
echo "Ready to deploy"
