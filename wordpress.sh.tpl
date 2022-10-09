#!/bin/bash
sudo apt update  -y
sudo apt upgrade  -y
sudo apt install -y php
sudo apt install -y php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,bcmath,json,xml,intl,zip,imap,imagick}
sudo apt install -y mysql-client-core-8.0

sudo usermod -a -G www-data ubuntu
sudo chown -R ubuntu:www-data /var/www
sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod 0664 {} \;
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
sudo wp core download --path=/var/www/html --allow-root
