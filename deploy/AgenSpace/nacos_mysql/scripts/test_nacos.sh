#!/bin/bash

set -euo pipefail

NACOS_URL="${NACOS_URL:-http://192.168.33.91:8848/nacos}"
NEW_USERNAME="nacos"
NEW_PASSWORD="abc!@111"

printf "Testing Nacos endpoint: %s\n" "$NACOS_URL"

printf "1. Checking readiness...\n"
if curl -sf "${NACOS_URL}/v1/console/health/readiness" > /dev/null; then
  echo "Nacos readiness OK"
else
  echo "Failed to contact Nacos readiness endpoint" >&2
  exit 1
fi

printf "2. Creating (or updating) user %s...\n" "$NEW_USERNAME"
CREATE_RESPONSE=$(curl -s -X POST "${NACOS_URL}/v1/auth/users?username=${NEW_USERNAME}&password=${NEW_PASSWORD}")

echo "Response: $CREATE_RESPONSE"
CODE=$(echo "$CREATE_RESPONSE" | grep -o '"code"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*"code"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/' || true)

if [ -n "$CODE" ] && [ "$CODE" != "200" ]; then
  echo "Operation may have failed with code $CODE" >&2
  exit 1
fi

echo "User operation completed successfully."
