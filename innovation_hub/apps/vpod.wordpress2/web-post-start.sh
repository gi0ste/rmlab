#!/bin/bash
exec > >(tee -a /var/tmp/init_configurewordpress_$$.log) 2>&1

# Source the Cloudcenter user env file to onboard C3 specifc vars

. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/cfgutil.sh
. /usr/local/osmosix/service/utils/agent_util.sh


agentSendLogMessage Attempting to configure Wordpress using curl using $CliqrTier_apache2_1_IP > /dev/null 2>&1

WP_ROOT=/var/www/wordpress

echo -n "Configuring Wordpress ... "

if [ -e $WP_ROOT/wp-config.php ]; then sudo rm -f $WP_ROOT/wp-config.php; fi

sed -e 's/database_name_here/wordpress/' \
-e 's/username_here/root/' \
-e 's/password_here/welcome2cliqr/' \
-e 's/localhost/'$CliqrTier_mysql_1_IP'/' \
-e 's/utf8/utf8mb4/' \
$WP_ROOT/wp-config-sample.php | sudo tee -a $WP_ROOT/wp-config.php > /dev/null

iRetries=9
iPause=5

while [ $iRetries -ge 0 ]; do

  OUT=($(curl -s -i --data-urlencode "weblog_title=$wp_site_name" --data-urlencode "user_name=dcloud" --data-urlencode "admin_password=C1sco12345" --data-urlencode "admin_password2=C1sco12345" --data-urlencode "admin_email=me@me.com" --data-urlencode "Submit=Install+WordPress" http://$CliqrTier_apache2_1_IP/wordpress/wp-admin/install.php?step=2 ))
  ret=$?

  if [ $ret -eq 0 ] && [ ${OUT[1]} == "200" ]; then
    echo "Success!"
    agentSendLogMessage Completed the configuration of Wordpress site $wp_site_name using curl on $CliqrTier_apache2_1_IP > /dev/null 2>&1
    exit 0
  fi
  echo "Failed! Error code: $ret, http code: ${OUT[1]}, retries left: $iRetries, http output: ${OUT[@]}"
  sleep $iPause
  ((iRetries--))

done

echo "Failed to perform the initial Wordpress configuration"
agentSendLogMessage Failed applying the configuration of Wordpress using curl on $CliqrTier_apache2_1_IP. Error code $ret > /dev/null 2>&1
exit 1
