#!/bin/bash -x
source /usr/local/osmosix/etc/userenv

sudo sed -e "s/%CliqrTier_DSERVER_PUBLIC_IP%/$CliqrTier_DSERVER_PUBLIC_IP/" /var/www/wp-config.php