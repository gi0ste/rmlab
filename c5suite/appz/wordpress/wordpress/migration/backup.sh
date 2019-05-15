#!/bin/bash

. /usr/local/osmosix/etc/request_util.sh
echo $OSMOSIX_PUBLIC_IP > /tmp/oldServerIp
backupFile oldServerIp_$CliqrDeploymentId /tmp/oldServerIp
cd /var/www
zip -r /tmp/wordpress.zip *
backupFile wordpress_$CliqrDeploymentId.zip /tmp/wordpress.zip
