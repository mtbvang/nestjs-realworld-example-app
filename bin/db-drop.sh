#!/bin/bash

set -e

# Based on http://www.postgresqltutorial.com/postgresql-drop-database/

echo "Dropping DB, DB user and extensions"
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_DB: $POSTGRES_DB"
echo "POSTGRES_HOST: $POSTGRES_HOST"
echo "APP_USER: $APP_USER"
echo "APP_USER_PASSWORD: $APP_USER_PASSWORD"

psql -v -X --set ON_ERROR_STOP=1 --port $DB_PORT --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --host "$POSTGRES_HOST"<<-EOSQL
    DROP DATABASE IF EXISTS $APP_DATABASE;
    drop role if exists $APP_USER;
    drop extension if exists "uuid-ossp";
EOSQL

echo "Finished dropping DB, DB user and extensions"

