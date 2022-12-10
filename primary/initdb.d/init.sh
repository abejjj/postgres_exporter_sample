#!/bin/bash
set -euxo

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF
create role rep with login replication password 'rep';
create role postgres_exporter with login password 'postgres_exporter';
select * from pg_create_physical_replication_slot('replica1_slot');
select * from pg_create_physical_replication_slot('replica2_slot');

create table transaction_1
(
    id	                serial                  not null
,   created_at          timestamp default now() not null
,   note                varchar(2000)           not null
,   constraint          pk_transaction_1 primary key (id)
)
;

insert into transaction_1   (note   ) 
values                      ('test1')
,                           ('test2')
,                           ('test3')
;

EOF

sed -i -e '/^host\s\+all\s\+all\s\+all.*/d' "$PGDATA/pg_hba.conf"

cat >> "$PGDATA/pg_hba.conf" <<EOF
host all ${POSTGRES_USER} 0.0.0.0/0 trust
host replication ${POSTGRES_USER} 0.0.0.0/0 trust
host all rep 0.0.0.0/0 trust
host all postgres_exporter 0.0.0.0/0 trust
EOF

cat > "$PGDATA/postgresql.conf" <<EOF
# CONNECTION
listen_addresses = '*'
port = 5432
# VACUUM / ANALYZE
autovacuum = on
track_counts = on
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
max_wal_senders = 10
hot_standby_feedback = on
hot_standby = on
wal_level = replica
synchronous_standby_names = '*'
#PROMETHEUS
shared_preload_libraries = 'pg_stat_statements'
EOF

pg_ctl reload -D ${PGDATA}

until pg_ctl stop -D ${PGDATA} ; do echo "Waiting for stop database..."; sleep 1s ; done

until pg_ctl start -D ${PGDATA} ; do echo "Waiting for start database..."; sleep 1s ; done

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOF

alter role postgres_exporter set search_path to postgres_exporter,pg_catalog;
grant connect on database postgres to postgres_exporter;
grant connect on database ${POSTGRES_DB} to postgres_exporter;
grant pg_monitor to postgres_exporter;

EOF

exit