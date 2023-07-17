CREATE USER 'appuser'@'%' IDENTIFIED WITH mysql_native_password BY 'cM5*6@FmhfIyV9;';

GRANT SELECT, INSERT, UPDATE, DELETE ON sampledb.* TO 'appuser'@'%';

CREATE DATABASE IF NOT EXISTS sampledb;

USE sampledb;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL
);
