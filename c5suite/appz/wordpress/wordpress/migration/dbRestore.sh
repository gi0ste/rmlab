#!/bin/bash
. /usr/local/cliqr/etc/request_util.sh

restoreFile dbBackup_$migrateFromDepId.sql /tmp/dbBackup.sql
cd /tmp
mysql -u scott -ptiger wpdb < dbBackup.sql

