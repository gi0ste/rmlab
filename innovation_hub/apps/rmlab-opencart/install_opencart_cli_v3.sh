#!/bin/bash
exec > >(tee -a /var/tmp/config-opencart-init_$$.log) 2>&1

OSMOSIX_BASE_DIR=/usr/local/osmosix
OPENCART_INSTALLED_FILE=$OSMOSIX_BASE_DIR/etc/.OPENCART_INSTALLED
SCRIPTNAME=$(basename $0)

if [ -f $OPENCART_INSTALLED_FILE ]; then echo "OpenCart already installed"; exit; fi

# ensure running as root
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@"
fi

if [ -f /usr/local/osmosix/etc/userenv ]; then source /usr/local/osmosix/etc/userenv; fi

#Apache_IP=$CliqrTier_Apache_PUBLIC_IP
#[ -z $Apache_IP ] && Apache_IP=$CliqrTier_Apache_IP

declare -a IP_VARs=()

IP_VARs+=$(set | egrep -v "PUBLIC" | egrep -i "CliqrTier_haproxy_.*IP" | cut -d'=' -f1 )
IP_VARs+=$(set | egrep -v "PUBLIC" | egrep -i "CliqrTier_nginx_.*IP" | cut -d'=' -f1 )
IP_VARs+=("cliqrNodePrivateIp")

unset Apache_IP
for iv in ${IP_VARs[@]}; do
  if [ ! -z ${!iv} ]; then
    Apache_IP=${!iv}
    break
  fi
done

unset IP_VARs

Database_IP=$CliqrTier_Database_IP

if [ -z $Apache_IP ]; then
  echo Could not determine Web Server IP Address
  exit 4
elif [ -z $Database_IP ]; then
  echo Could not determine Database Server IP Address
  exit 5
fi

echo DB: $Database_IP, Web:$Apache_IP
sleep 1

WEBROOT=/var/www/html


if [ -f /var/www/index.php ]; then
  if [ -d $WEBROOT ]; then rmdir $WEBROOT; fi
  ln -s /var/www $WEBROOT
fi

# Copy script to container-accessible directory
if [ ! -f $WEBROOT/$SCRIPTNAME ]; then cp $0 $WEBROOT/$SCRIPTNAME; fi

cd $WEBROOT
if [ $? -ne 0 ]; then echo "ERROR: Could not CD to $WEBROOT"; exit 1; fi

if [ -f config-dist.php ]; then mv config-dist.php config.php; fi
if [ -f .htaccess.txt ]; then mv .htaccess.txt .htaccess; fi
if [ -f admin/config-dist.php ]; then mv admin/config-dist.php admin/config.php; fi

if [ "$(stat -c '%u:%g' index.php)" != "33:33" ]; then
  echo Setting file ownership
  chown -R 33:33 *
fi

# Apache config to enable SEO
for FI in "/etc/apache2/apache2.conf" "/etc/apache2/sites-enabled/default" "/etc/httpd/conf/httpd.conf" "/etc/httpd/sites-available/default"; do
  if [ -f $FI ]; then
    sed -i '\|^\s*<Directory /var/www/html/>|,\|^\s*</Directory>| s|AllowOverride None|AllowOverride All|' $FI
  fi
done

# Opencart Settings to Enable SEO
if grep -q "'config_seo_url', '0'" $WEBROOT/install/opencart.sql; then
  sed -i "s|'config_seo_url', '0'|'config_seo_url', '1'|" $WEBROOT/install/opencart.sql
fi

if [ ! -d /var/www-private ]; then mkdir -p /var/www-private; fi

WRONG_CON_ID=$(docker ps 2> /dev/null | grep " php:5.6-apache " | head -n 1 | awk '{print $1}')
if [ ! -z $WRONG_CON_ID ]; then
  CIMG="ss-registry.dcv.svpod/ss-demos/php:5.6-apache-ccs"

  echo Disposing of container with insufficient PHP Modules installed.
  docker kill $WRONG_CON_ID > /dev/null; docker rm $WRONG_CON_ID > /dev/null
  if [ ! -d /etc/docker/certs.d/ss-registry.dcv.svpod ]; then mkdir -p /etc/docker/certs.d/ss-registry.dcv.svpod; fi
  if [ ! -f /etc/docker/certs.d/ss-registry.dcv.svpod/ca.crt ]; then
    echo Populating ss-registry.dcv.svpod Private Registry certificate
    openssl s_client -connect ss-registry.dcv.svpod:443 < /dev/null 2> /dev/null | openssl x509 -outform pem > /etc/docker/certs.d/ss-registry.dcv.svpod/ca.crt
    if [ $? -ne 0 ]; then echo "ERROR: Failed to populate Private Registry certificate"; exit 1; fi
  fi
  echo Recreating container with sufficient PHP Modules installed.
  if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$CIMG"; then
    echo Pulling image $CIMG
    docker pull $CIMG > /dev/null
    if [ $? -ne 0 ]; then echo ERROR: Could not pull image $CIMG; exit 1; fi
  fi
  echo Creating new container
  CON_NEW=$(docker create -w /var/www/html \
    -v /etc/apache2/sites-available:/etc/apache2/sites-available \
    -v /etc/apache2/sites-enabled:/etc/apache2/sites-enabled \
    -v /usr/local/osmosix/cert:/etc/apache2/cert \
    -v /etc/apache2/apache2.conf:/etc/apache2/apache2.conf \
    -v /var/www:/var/www/html \
    -v /var/www-private:/var/www/private \
    -p 80:80/tcp \
    -p 443:443/tcp \
    --name=apache2 \
    ss-registry.dcv.svpod/ss-demos/php:5.6-apache-ccs)
  echo Starting container
  docker start $CON_NEW

  # Container is up?
  er=0
  for ISUP in $(seq 90 -1 1); do
    CON_ID=$(docker ps | grep apache2 | head -n 1 | awk '{print $1}')
    docker inspect $CON_ID 2> /dev/null | grep "Status" | grep -q "running"
    er=$?
    if [ $er -eq 0 ]; then break; fi
    sleep 1
  done
  if [ $er -ne 0 ]; then echo "ERROR: Container didn't come up in a timely manner"; exit 1; fi

fi

CON_ID=$(docker ps 2> /dev/null | grep apache2 | head -n 1 | awk '{print $1}')

if [ ! -z $CON_ID ]; then
  echo Apache Docker Container detected. Relaunching initialisation script from from within container.
  docker exec $CON_ID /bin/bash -c "( export cliqrNodePrivateIp=$Apache_IP; export CliqrTier_Database_IP=$Database_IP; $WEBROOT/$SCRIPTNAME )"
  exit $?
fi


# When not in a container, execute the apache config changes and restart commands
if cat /proc/1/sched | head -n 1 | egrep "^init "; then
  if [ -f /usr/lib/systemd/system/httpd.service ]; then
    systemctl restart httpd
  else
    service httpd restart
  fi
fi


cd $WEBROOT/install

iRetries=9
iPause=3

echo -n "Configuring Opencart ... "
while [ $iRetries -ge 0 ]; do  

  php cli_install.php install --db_driver mysqli --db_hostname $CliqrTier_Database_IP --db_username opencart --db_password opencart --db_name opencart --username admin --password admin --email youremail@example.com --agree_tnc yes --http_server http://$Apache_IP/

  er=$?
  if [ $er -eq 0 ]; then
    echo "Success!"
    touch $OPENCART_INSTALLED_FILE 2> /dev/null

    
    STORAGEROOT=/var/www/private
    echo Moving Storage Dir from $WEBROOT/system to $STORAGEROOT
    if [ -d $WEBROOT/system/storage ]; then
      mv $WEBROOT/system/storage $STORAGEROOT/
      if [ $? -ne 0 ]; then echo "Move of Storage Dir failed"; exit 1; fi
      DIR_STORAGE=$STORAGEROOT/storage/
      for VI in "DIR_STORAGE"; do
        if [ ! -z ${!VI} ]; then
          for FI in "$WEBROOT/config.php" "$WEBROOT/admin/config.php"; do
            sed -i "s|^define('${VI}'.*$|define('${VI}', '${!VI}');|" $FI
          done
        fi
      done
    fi

    echo "done"

    exit 0
  fi
  echo "Failed! Error code: $er, retries left: $iRetries"
  sleep $iPause
  ((iRetries--))

done

echo "Failed to perform the initial Opencart configuration"
exit 1
