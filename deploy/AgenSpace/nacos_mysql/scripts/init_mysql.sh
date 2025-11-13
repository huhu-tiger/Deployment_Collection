#!/bin/bash

set -e

MYSQL_HOST="${MYSQL_HOST:-agent-space-mysql}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
DB_NAME="${DB_NAME:-nacos_config}"
SCHEMA_FILE="${SCHEMA_FILE:-/mysql-schema.sql}"
MAX_WAIT_TIME=${MAX_WAIT_TIME:-60}

if [ -z "$MYSQL_PASSWORD" ]; then
  echo "MYSQL_PASSWORD not set, cannot initialize database"
  exit 1
fi

echo "Waiting for MySQL to be ready..."
# 等待 MySQL 启动
for i in $(seq 1 $MAX_WAIT_TIME); do
  if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
    echo "MySQL is ready."
    break
  fi
  if [ $i -eq $MAX_WAIT_TIME ]; then
    echo "MySQL did not become ready within ${MAX_WAIT_TIME} seconds"
    exit 1
  fi
  sleep 1
done

db_exists=$(mysql -N -s -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${DB_NAME}'" || true)
if [ -n "$db_exists" ]; then
  echo "Database ${DB_NAME} already exists. Skip initialization."
  exit 0
fi

echo "Creating database ${DB_NAME}..."
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EOF

echo "Database ${DB_NAME} created."

if [ -f "$SCHEMA_FILE" ]; then
  echo "Importing schema from ${SCHEMA_FILE}..."
  mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DB_NAME" < "$SCHEMA_FILE"
  echo "Schema import completed."
else
  echo "Schema file ${SCHEMA_FILE} not found. Skip importing schema."
fi

