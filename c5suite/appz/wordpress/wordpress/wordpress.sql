create database wpdb;
CREATE USER 'scott'@'%' IDENTIFIED BY 'tiger';
GRANT ALL PRIVILEGES ON wpdb.* TO 'scott'@'%';
