use wpdb;
update wp_options set option_value= REPLACE(option_value,'%OLD_SERVER_IP%','%APP_SERVER_IP%') where option_name = 'home' or option_name = 'siteurl';
update wp_posts set post_content = REPLACE(post_content,'%OLD_SERVER_IP%','%APP_SERVER_IP%');
update wp_posts set guid = REPLACE(guid,'%OLD_SERVER_IP%','%APP_SERVER_IP%');
