#!/bin/bash
. /usr/local/osmosix/service/utils/cfgutil.sh
. /usr/local/cliqr/etc/request_util.sh

export appServerIp=$OSMOSIX_PUBLIC_IP
restoreFile oldServerIp_$migrateFromDepId /tmp/oldServerIp
ipfile=/tmp/oldServerIp
export oldServerIp=`cat "$ipfile"`
cd /tmp
wget http://edu-repo.cliqr.com/4x/apps/wordpress/migration/migration.sql
replaceToken /tmp/migration.sql '%APP_SERVER_IP%' $appServerIp
replaceToken /tmp/migration.sql '%OLD_SERVER_IP%' $oldServerIp
mysql -ptiger -u scott -h $CliqrTier_Database1_IP < /tmp/migration.sql

cd /var/www
cp wp-config.php /tmp
rm -R *
restoreFile wordpress_$migrateFromDepId.zip /tmp/wordpress.zip
unzip /tmp/wordpress.zip
cp /tmp/wp-config.php /var/www
chown -R www-data:www-data /var/www
