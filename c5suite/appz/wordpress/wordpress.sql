create database wpdb;
CREATE USER 'wpadmin'@'%' IDENTIFIED BY 'theSecretPwd';
GRANT ALL PRIVILEGES ON wpdb.* TO 'wpadmin'@'%';
FLUSH privileges;
