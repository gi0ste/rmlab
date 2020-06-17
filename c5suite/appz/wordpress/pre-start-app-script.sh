#!/bin/bash -x
source /usr/local/osmosix/etc/userenv

# Remove old PHP packages
#yum remove php.x86_64 php-cli.x86_64 php-common.x86_64 php-gd.x86_64 php-ldap.x86_64 php-mbstring.x86_64 php-mcrypt.x86_64 php-mysql.x86_64 php-pdo.x86_64 -y

for packages in $(yum list installed | grep -i php | cut -f1 -d "."); do yum remove -y $packages; done


# Configuring new repo for PHP55
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm

# Installing new PHP packages for owncloud

sudo sed -i "s/%CliqrTier_DSERVER_PUBLIC_IP%/$CliqrTier_DSERVER_PUBLIC_IP/" /var/www/wp-config.php
