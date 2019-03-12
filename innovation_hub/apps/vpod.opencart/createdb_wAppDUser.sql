-- Creates the DB structure
-- cli_installer.php inside the php app creates structure
CREATE DATABASE IF NOT EXISTS opencart;
CREATE USER 'opencart'@'%' IDENTIFIED BY 'opencart';
GRANT ALL PRIVILEGES ON opencart.* TO 'opencart'@'%';

CREATE USER 'appdynamics'@'%' IDENTIFIED BY 'C1sco12345';
GRANT ALL PRIVILEGES ON *.* TO 'appdynamics'@'%';

FLUSH PRIVILEGES;
