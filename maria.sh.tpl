#!/bin/bash
sudo apt update -y
sudo apt install -y mariadb-server

sudo mysql_secure_installation <<EOF
n
n
n
n
n
EOF

sudo mysql << EOF 
CREATE DATABASE ${database_name};

GRANT ALL ON *.* TO 'admin' @'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;

CREATE USER '${database_user}' @'localhost' IDENTIFIED BY '${database_pass}';

GRANT ALL PRIVILEGES ON *.* TO '${database_user}' @'localhost' WITH GRANT OPTION;

CREATE USER '${database_user}' @'%' IDENTIFIED BY '${database_pass}';

GRANT ALL PRIVILEGES ON *.* TO '${database_user}' @'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

exit
EOF

sudo chmod 777 /etc/mysql/my.cnf

echo "[mysqld]
skip-networking=0
skip-bind-address
" >> /etc/mysql/my.cnf

sudo systemctl restart mariadb
