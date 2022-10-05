#!/bin/bash
sudo apt update  -y
sudo apt upgrade -y
sudo apt update  -y
sudo apt upgrade -y
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
sudo wp config create --dbname=wordpress --dbuser=wp --dbpass=wordpress101 --dbhost=${private_ip_db}:3306 --path=/var/www/html --allow-root --extra-php <<PHP
define( 'FS_METHOD', 'direct' );
define('WP_MEMORY_LIMIT', '128M');
PHP
sudo chown -R ubuntu:www-data /var/www/html
sudo chmod -R 774 /var/www/html
sudo rm /var/www/html/index.html
sudo systemctl restart apache2
