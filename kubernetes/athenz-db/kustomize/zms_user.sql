CREATE USER 'zms_admin'@'%' IDENTIFIED BY 'athenz';
GRANT ALL PRIVILEGES ON zms_server.* TO 'zms_admin'@'%';
CREATE USER 'zms_admin'@'localhost' IDENTIFIED BY 'athenz';
GRANT ALL PRIVILEGES ON zms_server.* TO 'zms_admin'@'localhost';
FLUSH PRIVILEGES;
