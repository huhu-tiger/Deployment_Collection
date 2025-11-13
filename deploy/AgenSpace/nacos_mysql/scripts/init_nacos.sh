#!/bin/bash

set -e

# Nacos 默认配置
NACOS_URL="${NACOS_URL:-http://192.168.33.91:8848/nacos}"
MAX_WAIT_TIME=${MAX_WAIT_TIME:-120}
NEW_PASSWORD="${NACOS_PASSWORD:-}"

if [ -z "$NEW_PASSWORD" ]; then
  echo "NACOS_PASSWORD not set, skipping password initialization"
  exit 0
fi

echo "Waiting for Nacos to be ready..."
for i in $(seq 1 $MAX_WAIT_TIME); do
  if curl -sf "${NACOS_URL}/v1/console/health/readiness" > /dev/null 2>&1; then
    echo "Nacos is ready."
    break
  fi
  if [ $i -eq $MAX_WAIT_TIME ]; then
    echo "Nacos did not become ready within ${MAX_WAIT_TIME} seconds"
    exit 1
  fi
  sleep 1
done

echo "Initializing nacos user password via admin API..."
INIT_RESPONSE=$(curl -s -X POST "${NACOS_URL}/v1/auth/users/admin" \
  --data-urlencode "password=${NEW_PASSWORD}")

INIT_CODE=$(echo "$INIT_RESPONSE" | grep -o '"code"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*"code"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/' || true)

if [ -z "$INIT_CODE" ] || [ "$INIT_CODE" == "200" ]; then
  echo "Password initialization completed: $INIT_RESPONSE"
  exit 0
elif [ "$INIT_CODE" == "409" ]; then
  echo "Password already initialized previously: $INIT_RESPONSE"
  exit 0
else
  echo "Password initialization failed: $INIT_RESPONSE"
  exit 1
fi

