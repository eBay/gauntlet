#!/bin/bash

# Gauntlet setup script
## this should be run as root
if [ `whoami` != root ]; then
    echo Please run this script as root or using sudo
    exit
fi

echo "Install required packages"

apt-get -y install apache2 apache2-utils mysql-server libdbd-mysql-perl libdbi-perl mysql-client liburi-perl nmap sshpass


echo "Install extra Perl modules"




echo "Create MySQL database"

echo -n "What's the mysql root password? "
read mpass
#echo $mpass

echo -n "What username to use for the gauntlet DB? "
read dbuser

echo -n "What password to assign to the user? "
read dbpass

echo "create database gauntlet;" | mysql -uroot -p$mpass
echo "grant ALL on gauntlet.* to ${dbuser}@localhost identified by \"$dbpass\"" | mysql -uroot -p$mpass

echo "Load Gauntlet DB structure"
mysql -u"$dbuser" -p"$dbpass" gauntlet < etc/structure.sql 
echo "Update Apache2 config"
echo -n "Enter virtual host name to use for Apache config: "
read vhost

cat /ebay/gauntlet/etc/apache.conf.example | sed -e "s/CHANGEME/$vhost/g" > /etc/apache2/sites-enabled/$vhost
mkdir /etc/apache2/ssl
/usr/sbin/make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /etc/apache2/ssl/apache.pem

service apache2 restart

echo "Install SSH keys"
echo "You must copy SSH private keys into /ebay/gauntlet/keys"
echo "You can do this in another window. I'll wait for you. Press return when finished."
read finished

echo "Setting all keys permissions to mode 0600"
chmod 0600 /ebay/gauntlet/keys/*

echo "Configure Gauntlet"
echo "Now you must edit /ebay/gauntlet/lib/GauntletConfig.pm to associate the keys you"
echo "have just installed with specific subdomains. Once again, I'll wait!. Press return when done."
read finished


echo "Setup Gauntlet Web users"
echo "provide a web username: "
read webuser
echo "provide a password for it: "
read webpass

htpasswd /ebay/gauntlet/etc/htpasswd.users "$webuser" "$webpass"

echo "fix permissions on gauntlet spool directory"
mkdir -p /ebay/gauntlet/spool/unassigned
mkdir -p /ebay/gauntlet/spool/running
chgrp www-data /ebay/gauntlet/spool/unassigned
chmod g+s /ebay/gauntlet/spool/unassigned


echo "Load Gauntlet Crontab entries - note this replaces the crontab for the given user"
echo "What user would you like to run the Gauntlet Workers as? "
read users
crontab -u $users /ebay/gauntlet/etc/crontab.entries

echo "Start Gauntlet workers"
su - $users "/ebay/gauntlet/bin/startworkers.sh > /dev/null 2>&1 &"
echo "Gauntlet is now ready!"
