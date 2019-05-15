#!/bin/bash

. /usr/local/osmosix/etc/request_util.sh
mysqldump -u scott -ptiger wpdb > /tmp/dbBackup.sql
backupFile dbBackup_$CliqrDeploymentId.sql /tmp/dbBackup.sql
cd /var/www
zip -r /tmp/wordpress.zip *
backupFile wordpress_$CliqrDeploymentId.zip /tmp/wordpress.zip
