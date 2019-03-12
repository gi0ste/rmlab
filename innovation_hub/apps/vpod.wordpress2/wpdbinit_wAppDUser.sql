CREATE DATABASE wordpress;

GRANT ALL PRIVILEGES ON wordpress.* TO "root"@"hostname" IDENTIFIED BY "welcome2cliqr";

CREATE USER 'appdynamics'@'%' IDENTIFIED BY 'C1sco12345';
GRANT ALL PRIVILEGES ON *.* TO 'appdynamics'@'%';

FLUSH PRIVILEGES;
