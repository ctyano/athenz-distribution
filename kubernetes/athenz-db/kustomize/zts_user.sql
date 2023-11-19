CREATE USER 'zts_admin'@'%' IDENTIFIED BY 'athenz';
GRANT ALL PRIVILEGES ON zts_store.* TO 'zts_admin'@'%';
CREATE USER 'zts_admin'@'localhost' IDENTIFIED BY 'athenz';
GRANT ALL PRIVILEGES ON zts_store.* TO 'zts_admin'@'localhost';
FLUSH PRIVILEGES;
