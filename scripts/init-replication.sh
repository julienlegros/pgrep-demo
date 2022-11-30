#!/bin/bash
set -e

pg_primary_host="$1"
shift

create_db_directories() {
    # taken from the postgres docker image entrypoint
    local user; user="$(id -u)"
    mkdir -p "$PGDATA"
    chmod 700 "$PGDATA" || :
    mkdir -p /var/run/postgresql || :
    chmod 775 /var/run/postgresql || :
    if [ -n "${POSTGRES_INITDB_WALDIR:-}" ]; then
        mkdir -p "$POSTGRES_INITDB_WALDIR"
        if [ "$user" = '0' ]; then
            find "$POSTGRES_INITDB_WALDIR" \! -user postgres -exec chown postgres '{}' +
        fi
        chmod 700 "$POSTGRES_INITDB_WALDIR"
    fi
    if [ "$user" = '0' ]; then
        find "$PGDATA" \! -user postgres -exec chown postgres '{}' +
        find /var/run/postgresql \! -user postgres -exec chown postgres '{}' +
    fi
}

until PGPASSWORD=$POSTGRES_PASSWORD psql -h "${pg_primary_host}" -U "${POSTGRES_USER}" -d postgres -c '\q'; do
  >&2 echo "Postgres primary is unavailable - sleeping"
  sleep 1
  exit 1
done

>&2 echo "Postgres is up - executing command"

# create datadir and waldir
create_db_directories

# setup replication
if [ -z "$(ls -A ${PGDATA})" ]; then
    # empty dir
    su - postgres -c \
    "pg_basebackup -d 'postgresql://${POSTGRES_REP_USER}:${POSTGRES_REP_PASSWORD}@${pg_primary_host}?application_name=${POSTGRES_REP_APPNAME}' -D ${PGDATA} -X stream -P -Fp -R"
fi

# start cluster
exec ./docker-entrypoint.sh "$@"
