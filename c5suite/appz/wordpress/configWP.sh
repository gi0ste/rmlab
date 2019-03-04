#!/bin/bash

# Source the Cloudcenter user env file to onboard C3 specifc vars
source /usr/local/cliqr/etc/userenv

. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/cfgutil.sh
. /usr/local/osmosix/service/utils/agent_util.sh

agentSendLogMessage Attempting to configure Wordpress using curl using $CliqrTier_WSERVER_IP

curl --data-urlencode "weblog_title=$wp_site_name" --data-urlencode "user_name=$wp_user_name" --data-urlencode "admin_password=$wp_password"      --data-urlencode "admin_password2=$wp_password"      --data-urlencode "admin_email=$wp_admin_email"      --data-urlencode "Submit=Install+WordPress"      http://$CliqrTier_WSERVER_IP/wp-admin/install.php?step=2
