#!/bin/bash -x
source /usr/local/osmosix/etc/userenv

sudo sed -i "s/%CliqrTier_DSERVER_PUBLIC_IP%/$CliqrTier_DSERVER_PUBLIC_IP/" /var/www/wp-config.php
