#!/bin/sh
set -eu

psql \
  --set=ON_ERROR_STOP=1 \
  --set=litellm_db_user="$LITELLM_DB_USER" \
  --set=litellm_db_password="$LITELLM_DB_PASSWORD" \
  --set=litellm_db_name="$LITELLM_DB_NAME" <<'SQL'
SELECT format(
  'CREATE ROLE %I LOGIN PASSWORD %L',
  :'litellm_db_user',
  :'litellm_db_password'
)
WHERE NOT EXISTS (
  SELECT FROM pg_catalog.pg_roles WHERE rolname = :'litellm_db_user'
)
\gexec

SELECT format(
  'ALTER ROLE %I WITH LOGIN PASSWORD %L',
  :'litellm_db_user',
  :'litellm_db_password'
)
\gexec

SELECT format(
  'CREATE DATABASE %I OWNER %I',
  :'litellm_db_name',
  :'litellm_db_user'
)
WHERE NOT EXISTS (
  SELECT FROM pg_catalog.pg_database WHERE datname = :'litellm_db_name'
)
\gexec

SELECT format(
  'ALTER DATABASE %I OWNER TO %I',
  :'litellm_db_name',
  :'litellm_db_user'
)
\gexec
SQL
