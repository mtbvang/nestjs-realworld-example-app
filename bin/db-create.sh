#!/bin/bash

# This script is used by docker compose to initialize the database using the docker compose volume mount. To do
# migrations and to drop and recreate the database use the make targets provided in the root of this project.

set -e

echo "Creating DB, DB user and extensions"
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_DB: $POSTGRES_DB"
echo "POSTGRES_HOST: $POSTGRES_HOST"
echo "APP_USER: $APP_USER"
echo "APP_USER_PASSWORD: $APP_USER_PASSWORD"
echo "DB_PORT: $DB_PORT"

psql -v -X --set ON_ERROR_STOP=1 --port $DB_PORT --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --host "$POSTGRES_HOST" <<-EOSQL
    CREATE USER $APP_USER WITH LOGIN PASSWORD '$APP_USER_PASSWORD';
    CREATE DATABASE $APP_DATABASE;
    GRANT ALL PRIVILEGES ON DATABASE $APP_DATABASE TO $APP_USER;
EOSQL

# Check if rdsadmin user exists. If not we're on the docker environment and need to create both rdsadmin and master that already exists on AWS RDS databases.
psql  -v -X --set ON_ERROR_STOP=1 --port $DB_PORT --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --host "$POSTGRES_HOST" -tAc "SELECT 1 FROM pg_roles WHERE rolname='rdsadmin'" | grep -q 1 || psql -v -X --set ON_ERROR_STOP=1 --port $DB_PORT --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --host "$POSTGRES_HOST" <<-EOSQL
    create user rdsadmin
        superuser
        createdb
        createrole
        replication
        bypassrls
        valid until 'infinity';
    create user master
	    createdb
	    createrole
	    valid until 'infinity';
	commit;
    alter user rdsadmin set TimeZone = utc;
    alter user rdsadmin set log_min_error_statement = debug5;
    alter user rdsadmin set log_min_messages = panic;
    alter user rdsadmin set exit_on_error = 0;
    alter user rdsadmin set statement_timeout = 0;
    alter user rdsadmin set role = rdsadmin;
    alter user rdsadmin set auto_explain.log_min_duration = -1;
    alter user rdsadmin set temp_file_limit = -1;
    alter user rdsadmin set pg_hint_plan.enable_hint = off;
    alter user rdsadmin set default_transaction_read_only = off;
    alter user rdsadmin set search_path = pg_catalog, public;
EOSQL

# Create any extenions if needed.
#    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

echo "Finished creating DB, DB user and extensions"
