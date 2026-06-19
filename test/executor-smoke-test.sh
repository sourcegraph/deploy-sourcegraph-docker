#!/usr/bin/env bash
set -euo pipefail

# Executor smoke test for deploy-sourcegraph-docker
#
# Requires: a running Sourcegraph docker-compose stack (from smoke-test.sh or manual start).
# This script creates a site admin account, configures executor access, starts an executor
# container, and verifies it registers with the Sourcegraph instance.
#
# Dependencies: curl, jq, docker compose

FRONTEND_URL="${FRONTEND_URL:-http://localhost:80}"
EXECUTOR_TOKEN="executor-smoke-test-token"
ADMIN_EMAIL="smoke-test@sourcegraph.com"
ADMIN_USERNAME="smoke-admin"
ADMIN_PASSWORD="smoke-test-password-123!"
COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docker-compose" && pwd)"

echo "=== Executor Smoke Test ==="

# Step 1: Create initial site admin account
echo "Step 1: Creating site admin account..."
INIT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${FRONTEND_URL}/-/site-init" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"${ADMIN_EMAIL}\",\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\"}")
if [ "$INIT_STATUS" = "200" ] || [ "$INIT_STATUS" = "201" ]; then
    echo "  Site admin created"
elif [ "$INIT_STATUS" = "409" ]; then
    echo "  Site admin already exists, continuing"
else
    echo "  Warning: site-init returned HTTP $INIT_STATUS, attempting to continue"
fi

# Step 2: Sign in and extract session cookie
echo "Step 2: Signing in..."
SESSION_COOKIE=$(curl -s -D - -o /dev/null -X POST "${FRONTEND_URL}/-/sign-in" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}" \
    | tr -d '\r' | grep -i '^Set-Cookie: sgs=' | sed 's/^Set-Cookie: \([^;]*\).*/\1/')

if [ -z "$SESSION_COOKIE" ]; then
    echo "  FAILED: Could not obtain session cookie"
    exit 1
fi
echo "  Signed in"

# Step 3: Create access token
echo "Step 3: Creating access token..."
TOKEN=$(curl -s --cookie "$SESSION_COOKIE" -X POST "${FRONTEND_URL}/.api/graphql" \
    -H 'Content-Type: application/json' \
    -d '{"query":"mutation { createAccessToken(user: \"VXNlcjox\", scopes: [\"user:all\"], note: \"executor-smoke-test\") { token } }"}' \
    | jq -r '.data.createAccessToken.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "  FAILED: Could not create access token"
    exit 1
fi
echo "  Access token created"

# Step 4: Update site config with executor access token
echo "Step 4: Configuring executor access token in site config..."
LAST_ID=$(curl -s -X POST "${FRONTEND_URL}/.api/graphql" \
    -H "Authorization: token $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"query":"{ site { configuration { id } } }"}' \
    | jq -r '.data.site.configuration.id')

NEW_CONFIG=$(jq -n --arg token "$EXECUTOR_TOKEN" \
    '{"auth.providers": [{"type": "builtin"}], "executors.accessToken": $token} | tojson')

curl -s -o /dev/null -X POST "${FRONTEND_URL}/.api/graphql" \
    -H "Authorization: token $TOKEN" \
    -H 'Content-Type: application/json' \
    --data-raw "{\"query\":\"mutation UpdateSiteConfig(\$input: String!) { updateSiteConfiguration(lastID: $LAST_ID, input: \$input) }\", \"variables\":{\"input\":$NEW_CONFIG}}"
echo "  Site config updated"

# Step 5: Start executor container
echo "Step 5: Starting executor container..."
EXECUTOR_CONTAINER=$(docker compose \
    -f "${COMPOSE_DIR}/docker-compose.yaml" \
    -f "${COMPOSE_DIR}/executors/executor.docker-compose.yaml" \
    run -d \
    -e "EXECUTOR_FRONTEND_PASSWORD=${EXECUTOR_TOKEN}" \
    -e EXECUTOR_QUEUE_NAME=batches \
    executor 2>&1 | tail -1)
echo "  Executor container started: ${EXECUTOR_CONTAINER:0:12}"

# Step 6: Wait for executor to register
echo "Step 6: Waiting for executor to register..."
MAX_ATTEMPTS=24
for i in $(seq 1 $MAX_ATTEMPTS); do
    COUNT=$(curl -s -X POST "${FRONTEND_URL}/.api/graphql" \
        -H "Authorization: token $TOKEN" \
        -H 'Content-Type: application/json' \
        -d '{"query":"{ executors(query: \"\", active: false) { totalCount } }"}' \
        | jq -r '.data.executors.totalCount // 0')

    if [ "$COUNT" -ge 1 ] 2>/dev/null; then
        echo "  Executor registered after $((i * 5))s"
        echo ""
        echo "=== EXECUTOR SMOKE TEST PASSED ==="
        exit 0
    fi
    echo "  Attempt $i/$MAX_ATTEMPTS - waiting 5s..."
    sleep 5
done

echo ""
echo "=== EXECUTOR SMOKE TEST FAILED ==="
echo "Executor did not register within $((MAX_ATTEMPTS * 5))s"
echo ""
echo "Container status:"
docker inspect "$EXECUTOR_CONTAINER" --format '{{.State.Status}} (exit code: {{.State.ExitCode}})' 2>/dev/null || echo "  Container not found"
echo ""
echo "Container logs:"
docker logs "$EXECUTOR_CONTAINER" 2>&1 | tail -20 || echo "  No logs available"
exit 1
