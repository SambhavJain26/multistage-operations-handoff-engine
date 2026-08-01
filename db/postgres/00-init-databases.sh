#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  --set=n8n_password="$N8N_DB_PASSWORD" \
  --set=turndesk_db="$TURNDESK_DB" \
  --set=turndesk_user="$TURNDESK_DB_USER" \
  --set=turndesk_password="$TURNDESK_DB_PASSWORD" <<'SQL'
CREATE USER n8n WITH PASSWORD :'n8n_password';
CREATE DATABASE n8n OWNER n8n;

CREATE USER :"turndesk_user" WITH PASSWORD :'turndesk_password';
CREATE DATABASE :"turndesk_db" OWNER :"turndesk_user";
SQL
