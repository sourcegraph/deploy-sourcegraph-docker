#!/bin/bash

# Please ensure the variales in migration vars have been assigned before running this script. 

set -euxo pipefail

# shellcheck source=migration_vars
source migration_vars

image=${image:-sourcegraph/server}
sg_dump_file=$(mktemp)
codeintel_dump_file=$(mktemp)

trap 'rm -f ${sg_dump_file} ${codeintel_dump_file}' EXIT

# Get the  ID of the sourcegraph container
echo "Obtaing sourcegraph container ID"
container_id=$(ssh "${src_host}" docker ps | grep "${image}:${version}" | cut -f 1 -d ' ')

# Dump sourcegraph db and alter script for migration
echo "Dumping sourcegraph database"
ssh ${src_host} "docker exec ${container_id} pg_dump -C --username=postgres sourcegraph" >${sg_dump_file}
sed -i '/^CREATE DATABASE/a CREATE USER postgres WITH SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS;' ${sg_dump_file} >/dev/null 2>&1
printf '\connect -reuse-previous=on dbname=postgres\nDROP DATABASE sg;\nALTER DATABASE "sourcegraph" RENAME TO sg;\nALTER DATABASE sg OWNER TO sg;\n' >>${sg_dump_file}

# Dump codeintel db and alter script for migration
echo "Dumping codeintel database"
ssh ${src_host} "docker exec ${container_id} pg_dump -C --username=postgres sourcegraph-codeintel" >${codeintel_dump_file}
sed -i '/^CREATE DATABASE/a CREATE USER postgres WITH SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS;' ${codeintel_dump_file} >/dev/null 2>&1
printf '\connect -reuse-previous=on dbname=postgres\nDROP DATABASE sg;\nALTER DATABASE "sourcegraph-codeintel" RENAME TO sg;\nALTER DATABASE sg OWNER TO sg;\n' >>${codeintel_dump_file}

# Upload database dumps to new docker-compose deployment
echo "Uploading dumps to new deployment"
chmod 544 ${sg_dump_file} ${codeintel_dump_file}
scp ${sg_dump_file} "${dst_host}:${sg_dump_file}"
scp ${codeintel_dump_file} "${dst_host}:${codeintel_dump_file}"

# Migrate databases and start new deployment
ssh -t "${dst_host}" "
pushd ${compose_dir}
docker-compose down --volumes
docker-compose -f db-only-migrate.docker-compose.yaml up -d
sleep 10
docker cp ${sg_dump_file} pgsql:${sg_dump_file}
docker cp ${codeintel_dump_file} codeintel-db:${codeintel_dump_file}

echo 'Starting migration'
docker exec pgsql sh -c 'psql -v ERROR_ON_STOP=1 -U sg -f ${sg_dump_file} postgres'
docker exec codeintel-db sh -c 'psql -v ERROR_ON_STOP=1 -U sg -f ${codeintel_dump_file} postgres'

docker-compose -f docker-compose.yaml up -d
echo 'TEST: Checking frontend is accessible for 1 minute'

for i in {1..6}; do
curl -f http://localhost:80
curl -f http://localhost:80/healthz
sleep 10
done
echo 'Migration completed'
"
