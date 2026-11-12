#!/usr/bin/env bash
set -euo pipefail

# Executor smoke test for deploy-sourcegraph-docker
#
# Requires: a running Sourcegraph docker-compose stack with an executor container
# (from smoke-test.sh or manual start).
# This script creates a site admin account, configures executor access, and verifies
# the executor registers with the Sourcegraph instance, with every queue.
#
# Dependencies: curl, jq, docker

FRONTEND_URL="${FRONTEND_URL:-http://localhost:80}"
EXECUTOR_TOKEN=$(docker exec executor printenv EXECUTOR_FRONTEND_PASSWORD)
ADMIN_EMAIL="smoke-test@sourcegraph.com"
ADMIN_USERNAME="smoke-admin"
ADMIN_PASSWORD="smoke-test-password-123!"
# The queues test/docker-compose.override.yaml gives the executor, sorted
EXPECTED_QUEUE_NAMES="batches,batches-hooks,codeintel"

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

# Step 5: Wait for executor to register
echo "Step 5: Waiting for executor to register..."
MAX_ATTEMPTS=24
for i in $(seq 1 $MAX_ATTEMPTS); do
    EXECUTORS=$(curl -s -X POST "${FRONTEND_URL}/.api/graphql" \
        -H "Authorization: token $TOKEN" \
        -H 'Content-Type: application/json' \
        -d '{"query":"{ executors(query: \"\", active: false) { totalCount nodes { queueNames } } }"}')
    COUNT=$(jq -r '.data.executors.totalCount // 0' <<<"$EXECUTORS")

    if [ "$COUNT" -ge 1 ] 2>/dev/null; then
        echo "  Executor registered after $((i * 5))s"
        # One line per executor: its queue names, sorted
        QUEUE_NAMES=$(jq -r '.data.executors.nodes[] | .queueNames // [] | sort | join(",")' <<<"$EXECUTORS")
        if ! grep --quiet --line-regexp --fixed-strings "$EXPECTED_QUEUE_NAMES" <<<"$QUEUE_NAMES"; then
            echo ""
            echo "=== EXECUTOR SMOKE TEST FAILED ==="
            echo "No executor serves the queues \"$EXPECTED_QUEUE_NAMES\". Registered: \"$QUEUE_NAMES\""
            exit 1
        fi
        echo "  Executor serves the queues $EXPECTED_QUEUE_NAMES"
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
docker inspect executor --format '{{.State.Status}} (exit code: {{.State.ExitCode}})' 2>/dev/null || echo "  Container not found"
echo ""
echo "Container logs:"
docker logs executor 2>&1 | tail -20 || echo "  No logs available"
exit 1
