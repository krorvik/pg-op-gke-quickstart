# Moving a database from an oldschool VM to postgres-operated cluster

To move a database into a postgres-operated cluster, we recommend using WAL-G to place a PITR-enabled archive in a bucket the operated cluster has access to. The config for the old cluster is quite simple, and does not require outside access. 

We assume here we have a k8s cluster up and running, and the operator installed as the manifests in this repo shows. That is, a bucket called gs://rl-poc is available, and the cluster can read it (and preferably write to it, if you want your postgres-operated clusters backed up).

## Create a service account to use the bucket

We need to create a service account that can write to the bucket. The documentation at https://cloud.google.com/docs/authentication/production outlines the process. Use the button under "Creating a service account" to do so. Select "New service account" as type. 

Next, you need to give it permissions to create objects under storage. When you press "create", you will download a json file that we can use for authentication.

## Set up the old cluster

The internal master server needs to have WAL-G installed. We'll install the latest release at the time of writing, but please check if a newer version is out here first: https://github.com/wal-g/wal-g/releases. WAL-G is a statically compiled go binary, so it can be simply copied without dependencies. As root:

```console
# "krorvik" is the node used testing the procedure, this will be the name of your master server.
root@krorvik:~/temp# wget https://github.com/wal-g/wal-g/releases/download/v0.2.14/wal-g.linux-amd64.tar.gz
<SNIP>
2019-12-20 10:23:38 (6.96 MB/s) - ‘wal-g.linux-amd64.tar.gz’ saved [10403369/10403369]
 
root@krorvik:~/temp# tar zxpvf wal-g.linux-amd64.tar.gz
wal-g
root@krorvik:~/temp# chmod 755 wal-g
root@krorvik:~/temp# cp wal-g /usr/local/bin/
```

## Configure WAL-G

Create the default config file for wal-g, in /var/lib/postgresql/.walg.json. As postgres:

```/var/lib/postgresql/.walg.json
{
  "GOOGLE_APPLICATION_CREDENTIALS": "/var/lib/postgresql/gscreds.json",
  "PGHOST": "/var/run/postgresql",
  "WALG_GS_PREFIX": "gs://rl-poc/spilo/<clustername>"
}
```

Make sure you replace the correct bucketname and clustername.

Place the json file that you downloaded when creating the service account in the path given in GOOGLE_APPLICATION_CREDENTIALS. 

## Configure PostgreSQL

Finally, we set up the cluster so it actually archives WAL to the bucket. As postgres:

```console
postgres@krorvik:~$ psql
psql (12.1 (Debian 12.1-1.pgdg90+1))
Type "help" for help.
 
postgres=# alter system set archive_command to '/usr/local/bin/wal-g wal-push %p';
ALTER SYSTEM
 
postgres=# select pg_reload_conf();
 pg_reload_conf
----------------
 t
(1 row)
 
postgres=# select name, setting from pg_settings where name = 'archive_command';
      name       |            setting            
-----------------+---------------------------------
 archive_command | /usr/local/bin/wal-g wal-push %p
(1 row)
```

Using alter system like this will place the new value of archive_command in postgresql.auto.conf. Note that we are now effectively replacing the archiving commands that may be already set - if you want to combine methods, you must wrap this so postgres can relate to a single archive_command. 

Also take care if you are dependent on restore_command in your recovery configuration. 

The steps above usually do not replace any basebackups you may be doing, so that part should be good. Do note the relation to restore_command in your recovery routines though. 

## Check archiving works

At this point, you should call "select pg_switch_wal();" to see if segments are archived. Check that there are no ".ready" files in the wal folder on the master server - and that files appear in the bucket under the given path.  (Note: call "pg_switch_xlog()" in postgresql < 10)

# Prepare for postgres-operator configuration

This section applies only for debian based servers - for RHEL-based servers, you can skip this part. 

postgres-operator expects the cluster to clone to be set up by another postgres-operated pod. For debian based source clusters, two essential files are not present in the data directory. We therefore need to place them there, with a good set of defaults. Place these two files in the data directory in the source cluster. 

pg_hba.conf:

```
local   all             all                                   trust
host    all             all                127.0.0.1/32       md5
host    all             all                ::1/128            md5
hostssl replication     standby all                md5
hostnossl all           all                all                reject
hostssl all             all                all                md5
```

postgresql.conf:

```
archive_command = 'envdir "/home/postgres/etc/wal-e.d/env" wal-g wal-push "%p"'
archive_mode = 'on'
archive_timeout = '300'
autovacuum_analyze_scale_factor = '0.02'
autovacuum_max_workers = '5'
autovacuum_vacuum_scale_factor = '0.05'
bg_mon.listen_address = '0.0.0.0'
checkpoint_completion_target = '0.9'
cluster_name = 'rl-demo2-cluster'
extwlist.custom_path = '/scripts'
extwlist.extensions = 'btree_gin,btree_gist,citext,hstore,intarray,ltree,pgcrypto,pgq,pg_trgm,postgres_fdw,uuid-ossp,hypopg,pg_partman'
hot_standby = 'on'
listen_addresses = '*'
log_autovacuum_min_duration = '0'
log_checkpoints = 'on'
log_connections = 'on'
log_destination = 'csvlog'
log_directory = '../pg_log'
log_disconnections = 'on'
log_file_mode = '0644'
log_filename = 'postgresql-%u.log'
log_line_prefix = '%t [%p]: [%l-1] %c %x %d %u %a %h '
log_lock_waits = 'on'
log_min_duration_statement = '500'
log_rotation_age = '1d'
log_statement = 'ddl'
log_temp_files = '0'
log_truncate_on_rotation = 'on'
logging_collector = 'on'
max_connections = '100'
max_locks_per_transaction = '64'
max_prepared_transactions = '0'
max_replication_slots = '10'
max_wal_senders = '10'
max_worker_processes = '8'
pg_stat_statements.track_utility = 'off'
port = '5432'
shared_buffers = '204MB'
shared_preload_libraries = 'bg_mon,pg_stat_statements,pgextwlist,pg_auth_mon,set_user,pg_cron,pg_stat_kcache'
ssl = 'on'
ssl_cert_file = '/home/postgres/server.crt'
ssl_key_file = '/home/postgres/server.key'
tcp_keepalives_idle = '900'
tcp_keepalives_interval = '100'
track_commit_timestamp = 'off'
track_functions = 'all'
wal_keep_segments = '8'
wal_level = 'replica'
wal_log_hints = 'on'
hba_file = '/home/postgres/pgdata/pgroot/data/pg_hba.conf'
ident_file = '/home/postgres/pgdata/pgroot/data/pg_ident.conf'
```

## Perform a basebackup towards the bucket

Almost ready now - but we need to have a full basebackup present to be able to clone. As postgres:

```console
postgres@krorvik:~$ wal-g backup-push /var/lib/postgresql/12/main
INFO: 2019/12/20 10:49:42.066652 Doing full backup.
INFO: 2019/12/20 10:49:42.081660 Calling pg_start_backup()
INFO: 2019/12/20 10:49:42.116724 Walking ...
INFO: 2019/12/20 10:49:42.116877 Starting part 1 ...
INFO: 2019/12/20 10:49:47.594826 Finished writing part 1.
INFO: 2019/12/20 10:49:47.905237 Starting part 2 ...
INFO: 2019/12/20 10:49:47.905300 /global/pg_control
INFO: 2019/12/20 10:49:47.910406 Finished writing part 2.
INFO: 2019/12/20 10:49:47.912371 Calling pg_stop_backup()
INFO: 2019/12/20 10:49:48.965129 Starting part 3 ...
INFO: 2019/12/20 10:49:48.970310 backup_label
INFO: 2019/12/20 10:49:48.970401 tablespace_map
INFO: 2019/12/20 10:49:48.972616 Finished writing part 3.
INFO: 2019/12/20 10:49:49.326948 Wrote backup with name base_000000010000000000000023
```

At this point, a full basebackup is present in our gs bucket.

## Setting up the actual k8s cluster

Setting up a postgres-operated cluster now becomes as easy as the example rldemo-restore.yaml. 
