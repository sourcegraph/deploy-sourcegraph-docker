#!/bin/bash

set -euxo pipefail

# shellcheck source=migration_vars
source migration_vars

TMPFILE=$(mktemp)
IMAGE=${IMAGE:-sourcegraph/server}

trap 'rm -f "${TMPFILE}"' EXIT

CONTAINER_ID=$(ssh "${SRC_HOST}" docker ps | grep "${IMAGE}:${VERSION}" | cut -f 1 -d ' ')

ssh -t "${src_host}" "docker exec ${CONTAINER_ID} sh -c 'pg_dumpall --verbose --username=postgres' " >"${TMPFILE}"

ssh -t ${DST_HOST} "
pushd ${COMPOSE_DIR}
docker-compose down --volumes
docker-compose -f pgsql-only-migrate.docker-compose.yaml up -d
"

scp "$TMPFILE" "${DST_HOST}:$TMPFILE"

ssh -t "${DST_HOST}" "
docker cp ${TMPFILE} pgsql:${TMPFILE}
docker exec -u root pgsql sh -c 'psql -U sg -f ${TMPFILE} postgres'
docker exec pgsql sh -c 'psql -U sg postgres -c \"DROP DATABASE sg;\"'
docker exec pgsql sh -c 'psql -U sg postgres -c \"ALTER DATABASE sourcegraph RENAME TO sg; ALTER DATABASE sg OWNER TO sg;\"'
pushd ${COMPOSE_DIR}
docker-compose -f docker-compose.yaml up -d
sleep 30
curl localhost 2>&1 | grep sign-in
"


