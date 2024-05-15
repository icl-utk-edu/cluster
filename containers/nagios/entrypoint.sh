#!/bin/bash

mkdir -p /run/php-fpm
chown apache.apache /run/php-fpm
sudo -u apache /usr/sbin/php-fpm

/usr/sbin/httpd
#-DFOREGROUND

crond

chmod g+w  /var/spool/nagios/cmd
conf=/etc/nagios/nagios.cfg
/usr/sbin/nagios -v $conf
/usr/sbin/nagios $conf

