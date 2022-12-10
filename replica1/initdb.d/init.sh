#!/bin/bash
set -euxo

if [ -n "$PGDATA/PG_VERSION" ]; then
    echo "*:*:*:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > ~/.pgpass
    chmod 0600 ~/.pgpass

    until pg_isready -h postgres14-primary -p 5432 -U ${POSTGRES_USER}; do echo "Waiting for primary to ping..." ;sleep 1s; done

    until pg_ctl stop -D ${PGDATA} --mode=smart ; do echo "Waiting for stop database..."; sleep 1s ; done

    rm -rf ${PGDATA}/*

    until pg_basebackup -h postgres14-primary -D ${PGDATA} -U ${POSTGRES_USER} -vwPR; do echo "Waiting for restore database..."; sleep 1s ;done

    cat >> "$PGDATA/postgresql.conf" <<EOF
# TIMEZONE
timezone = 'Japan'
# LOG
log_statement = 'all'
log_timezone = 'Japan'
log_duration = on
log_directory = '/var/log/postgres'
log_filename = 'postgres_log.%Y%m%d_%H'
log_file_mode = 0644
logging_collector = on
log_destination=stderr
log_statement=all
log_connections=on
log_disconnections=on
# STREAMING REPLICATION
hot_standby_feedback = on
hot_standby = on
primary_conninfo = 'host=postgres14-primary port=15432 user=rep application_name=postgres14-replica1'
primary_slot_name = 'replica1_slot'
#PROMETHEUS
shared_preload_libraries = 'pg_stat_statements'
EOF

    until pg_ctl start -D ${PGDATA} ; do echo "Waiting for start database..."; sleep 1s ; done

fi

exit