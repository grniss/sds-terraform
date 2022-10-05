#!/bin/bash
sudo apt update
sudo apt install -y mariadb-server

sudo mysql_secure_installation <<EOF
n
n
n
n
n
EOF

sudo mysql << EOF 
CREATE DATABASE wordpress;

GRANT ALL ON *.* TO 'admin' @'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;

CREATE USER 'wp' @'localhost' IDENTIFIED BY 'wordpress101';

GRANT ALL PRIVILEGES ON *.* TO 'wp' @'localhost' WITH GRANT OPTION;

CREATE USER 'wp' @'%' IDENTIFIED BY 'wordpress101';

GRANT ALL PRIVILEGES ON *.* TO 'wp' @'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

exit
EOF

sudo chmod 777 /etc/mysql/my.cnf

echo "[mysqld]
skip-networking=0
skip-bind-address
" >> /etc/mysql/my.cnf

sudo systemctl restart mariadb
