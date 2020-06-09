#!/bin/bash

echo -e "\e[1m\e[32m***********************************************************\e[0m"
echo -e "\e[1m\e[32m**         Updating Amazon Linux Dependency.             **\e[0m"
echo -e "\e[1m\e[32m***********************************************************\e[0m"
sudo yum update -y
echo ""
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**     Installing LAMP with amazon-linux-extras.          **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2

echo -e "\e[1m\e[32m***********************************************************\e[0m"
echo -e "\e[1m\e[32m**              Installing httpd server.                 **\e[0m"
echo -e "\e[1m\e[32m***********************************************************\e[0m"
echo ""
sudo yum install -y httpd mariadb-server
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl is-enabled httpd

echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**      Adding user (ec2-user) to the apache group.       **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
sudo usermod -a -G apache ec2-user
groups

echo -e "\e[1m\e[32m**************************************************************************************************\e[0m"
echo -e "\e[1m\e[32m**    Changing the group ownership of /var/www and its contents to the apache group.            **\e[0m"
echo -e "\e[1m\e[32m**************************************************************************************************\e[0m"
echo ""
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;

#sudo yum list installed httpd mariadb-server php-mysqlnd
echo -e "\e[1m\e[32m***********************************************************\e[0m"
echo -e "\e[1m\e[32m**            Starting the MariaDB server.               **\e[0m"
echo -e "\e[1m\e[32m***********************************************************\e[0m"
echo ""
sudo systemctl start mariadb
sudo systemctl status mariadb

echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**             Installing mysql                           **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
sudo mysql_secure_installation
sudo systemctl stop mariadb
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**             Installing PHP dependencies                **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
sudo yum install php-mbstring -y
sudo yum install php-gd -y
sudo yum install php-xml -y
sudo systemctl restart httpd
sudo systemctl restart php-fpm

echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**             Logging-in MYSQL                           **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
sudo ./dbsetup.sh dbscript shelladmin shelladmin
sleep 2
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**             Downloading drupal                         **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
cd /var/www/html
wget https://ftp.drupal.org/files/projects/drupal-7.69.zip
sleep 1
files=$(find /var/www/html/ -type f -name '*.zip')
filename=$(basename -s . "$files")
foldername=$(basename -s .zip "$files")
sleep 1
unzip $filename
mv $foldername drupal
mkdir drupal/sites/default/files
cp drupal/sites/default/default.settings.php drupal/sites/default/settings.php
sudo chmod -R 777 drupal

echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**            Installing GIT, Composer and Drush          **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
sudo yum install git -y
git version
#cd drupal
#git init
#cd /var/www/html

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
ln -s /usr/local/bin/composer /usr/bin/composer
git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
cd /usr/local/src/drush
git checkout 8.x
git describe --abbrev=0 --tags
ln -s /usr/local/src/drush/drush /usr/bin/drush
composer install
drush --version
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**    Installing Drupal, Check login credentials Below    **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
cd /var/www/html/drupal
drush site-install standard --db-url='mysql://root:root@localhost/shelldrupal' --site-name=Drupal -y
echo ""
echo -e "\e[1m\e[32m** Database credentials name: shelldrupal, username: root, password: root  **\e[0m"
echo ""

# sudo mkdir /var/www/html/drupal/sites/ 
# ls /var/www/html/shellscript/modules/
# sudo wget https://ftp.drupal.org/files/projects/omega-7.x-5.0-alpha1.zip -P /var/www/html/shellscript/modules/
# ls /var/www/html/shellscript/modules/
# files=$(find /var/www/html/shellscript/modules/ -type f -name '*.zip')
# unzip $files -d /var/www/html/shellscript/modules
# sudo rm -r $files

echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**         Configuring Virtual Host                       **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
read -p "Enter site name: " SITE
read -p "Your Site path " SITEPATH
#/etc/hosts
sudo cp /etc/hosts /etc/hosts.original
echo -e "127.0.0.1\t${SITE}.local" >> /etc/hosts
#httpd-vhosts.conf
VHOSTSFILE="/etc/httpd/conf/httpd.conf"
sudo cp $VHOSTSFILE ${VHOSTSFILE}.original
sudo echo "<VirtualHost *:80>" >> $VHOSTSFILE
sudo echo -e "\tDocumentRoot \"${SITEPATH}\"" >> $VHOSTSFILE
sudo echo -e "\tServerName ${SITE}.local" >> $VHOSTSFILE
sudo echo -e "\tServerAlias ${SITE}.localhost" >> $VHOSTSFILE
sudo echo -e "\t<Directory \"${SITEPATH}\">" >> $VHOSTSFILE
sudo echo -e "\tOptions FollowSymLinks" >> $VHOSTSFILE
sudo echo -e "\tAllowOverride All" >> $VHOSTSFILE
sudo echo -e "\tAllow from all" >> $VHOSTSFILE
sudo echo -e "\tOrder allow,deny" >> $VHOSTSFILE
sudo echo -e "\t</Directory>" >> $VHOSTSFILE
sudo echo '</VirtualHost>' >> $VHOSTSFILE
sudo systemctl restart httpd

echo -e "\e[1m\e[32m************************************************************\e[0m"
echo -e "\e[1m\e[32m**        Browse Drupal on below IP: \e[0m                **\e[0m"
echo -e "\e[1m\e[32m************************************************************\e[0m"
echo ""
dig +short myip.opendns.com @resolver1.opendns.com

