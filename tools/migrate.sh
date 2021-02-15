#!/bin/bash

set -uxo pipefail

# shellcheck source=migration_vars
source migration_vars

IMAGE=${IMAGE:-sourcegraph/server}
sg_dump_file=$(mktemp)
codeintel_dump_file=$(mktemp)

trap 'rm -f ${sg_dump_file} ${codeintel_dump_file}' EXIT

# Get the  ID of the sourcegraph container
CONTAINER_ID=$(ssh "${SRC_HOST}" docker ps | grep "${IMAGE}:${VERSION}" | cut -f 1 -d ' ')

# Dump sourcegraph db and alter script for migration
ssh ${SRC_HOST} "docker exec ${CONTAINER_ID} pg_dump -C --username=postgres sourcegraph" >${sg_dump_file}
sed '/^CREATE DATABASE/a CREATE USER postgres WITH SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS;' ${sg_dump_file}
printf '\connect -reuse-previous=on dbname=postgres\nDROP DATABASE sg;\nALTER DATABASE "sourcegraph" RENAME TO sg;\nALTER DATABASE sg OWNER TO sg;\n' >> ${sg_dump_file}

# Dump codeintel db and alter script for migration
ssh ${SRC_HOST} "docker exec ${CONTAINER_ID} pg_dump -C --username=postgres sourcegraph-codeintel" >${codeintel_dump_file}
sed '/^CREATE DATABASE/a CREATE USER postgres WITH SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS;' ${codeintel_dump_file}
printf '\connect -reuse-previous=on dbname=postgres\nDROP DATABASE sg;\nALTER DATABASE "sourcegraph-codeintel" RENAME TO sg;\nALTER DATABASE sg OWNER TO sg;\n' >> ${codeintel_dump_file}

# Upload database dumps to new docker-compose deployment
chmod 544 ${sg_dump_file} ${codeintel_dump_file}
scp ${sg_dump_file} "${DST_HOST}:${sg_dump_file}"
scp ${codeintel_dump_file} "${DST_HOST}:${codeintel_dump_file}"

# Migrate databases and start new deployment
ssh -t "${DST_HOST}" "
pushd ${COMPOSE_DIR}
docker-compose down --volumes
docker-compose -f db-only-migrate.docker-compose.yaml up -d
sleep 10
docker cp ${sg_dump_file} pgsql:${sg_dump_file}
docker cp ${codeintel_dump_file} codeintel-db:${codeintel_dump_file}

docker exec pgsql sh -c 'psql -v ERROR_ON_STOP=1 -U sg -f ${sg_dump_file} postgres'
docker exec codeintel-db sh -c 'psql -v ERROR_ON_STOP=1 -U sg -f ${codeintel_dump_file} postgres'

docker-compose -f docker-compose.yaml up -d
echo 'TEST: Checking frontend is accessible for 1 minute'

for i in {1..6}; do
curl -f http://localhost:80
curl -f http://localhost:80/healthz
sleep 10
done
"

