#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  --set=n8n_password="$N8N_DB_PASSWORD" \
  --set=make_ready_db="$MAKE_READY_DB" \
  --set=make_ready_user="$MAKE_READY_DB_USER" \
  --set=make_ready_password="$MAKE_READY_DB_PASSWORD" <<'SQL'
CREATE USER n8n WITH PASSWORD :'n8n_password';
CREATE DATABASE n8n OWNER n8n;

CREATE USER :"make_ready_user" WITH PASSWORD :'make_ready_password';
CREATE DATABASE :"make_ready_db" OWNER :"make_ready_user";
SQL
