#!/bin/bash

set -euxo pipefail

# shellcheck source=migration_vars
source migration_vars

IMAGE=${IMAGE:-sourcegraph/server}
# trap 'rm -f ./*pg.out' EXIT

CONTAINER_ID=$(ssh "${SRC_HOST}" docker ps | grep "${IMAGE}:${VERSION}" | cut -f 1 -d ' ')

ssh -t "${SRC_HOST}" "docker exec ${CONTAINER_ID} sh -c 'pg_dumpall --verbose --username=postgres' " >sourcegraph_pgall.out
# ssh -t "${SRC_HOST}" "docker exec ${CONTAINER_ID} sh -c 'pg_dump --verbose --username=postgres sourcegraph-codeintel' " >codeintel_pg.out


chmod 777 ./*pg.out
scp ./*pg.out "${DST_HOST}:/tmp/"

ssh -t "${DST_HOST}" "
pushd ${COMPOSE_DIR}
docker-compose down --volumes
docker-compose -f pgsql-only-migrate.docker-compose.yaml up -d
sleep 15
docker cp /tmp/sourcegraph_pgall.out pgsql:/tmp/
"

# docker exec pgsql sh -c 'psql -v ERROR_ON_STOP=1 -U sg -f /tmp/sourcegraph_pg.out postgres'
#  docker exec pgsql sh -c 'psql -U sg postgres -c \"DROP DATABASE sg;\"'
# docker exec pgsql sh -c 'psql -U sg postgres -c \"ALTER DATABASE sourcegraph RENAME TO sg; ALTER DATABASE sg OWNER TO sg;\"'
# docker cp codeintel_pg.out codeintel-db:/tmp/
# docker exec codeintel-db sh -c 'psql -U sg -f /tmp/codeintel_pg.out postgres'
# docker exec codeintel-db sh -c 'psql -U sg postgres -c \"DROP DATABASE sg;\"'
# docker exec codeintel-db sh -c 'psql -U sg postgres -c \"ALTER DATABASE sourcegraph-codeintel RENAME TO sg; ALTER DATABASE sg OWNER TO sg;\"'

# pushd ${COMPOSE_DIR}
# docker-compose -f docker-compose.yaml up -d
# sleep 30
# curl localhost 2>&1 | grep sign-in
