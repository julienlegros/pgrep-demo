# Docker-compose configuration for running a local PostgreSQL replication

## Environment preparation
Set up some environment variables. Note that you must use a user writable path for `PG_DATA_ROOT`.

```sh
export PG_DATA_ROOT=/path/to/pg/data
export POSTGRES_PASSWORD=odoo
export POSTGRES_REP_USER=rep
export POSTGRES_REP_PASSWORD=rep
export POSTGRES_REP_APPNAME_1=rep_1
```

For more convenience, you can store the environment variables in the `.env` file next to `docker-compose.yml`.

```sh
cat > ./.env <<EOF
PG_DATA_ROOT=${PG_DATA_ROOT}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_REP_USER=${POSTGRES_REP_USER}
POSTGRES_REP_PASSWORD=${POSTGRES_REP_PASSWORD}
POSTGRES_REP_APPNAME_1=${POSTGRES_REP_APPNAME_1}
EOF
```

## Starting the PostgreSQL instances

Launch the PostgreSQL instances with

```sh
docker-compose up
```

The replication will be initialized. Connect to the PostgreSQL instances using

```
# primary
psql -U odoo -d postgres -h 10.54.0.32 -p 5432
# replica
psql -U odoo -d postgres -h 10.54.0.33 -p 5432
```

## Enable synchronous replication

Once the replication has been initialized, you can switch to a synchronous mode by editing `replication_primary.conf` and uncommenting the `synchronous_commit` and `synchronous_standby_names` parameters. It's necessary to restart the primary to apply the changes.
