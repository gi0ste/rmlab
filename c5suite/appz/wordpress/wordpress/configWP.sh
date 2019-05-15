#!/bin/bash

# Source the Cloudcenter user env file to onboard C3 specifc vars
source /usr/local/cliqr/etc/userenv

curl --data-urlencode "weblog_title=$wp_site_name" --data-urlencode "user_name=$wp_user_name" --data-urlencode "admin_password=$wp_password"      --data-urlencode "admin_password2=$wp_password"      --data-urlencode "admin_email=$wp_admin_email"      --data-urlencode "Submit=Install+WordPress"      http://$CliqrTier_WSERVER_IP/wp-admin/install.php?step=2
