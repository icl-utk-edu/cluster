#!/bin/bash

chmod g+w  /var/spool/nagios/cmd
conf=/etc/nagios/nagios.cfg
/usr/sbin/nagios -v $conf
/usr/sbin/nagios -d $conf

mkdir -p /run/php-fpm
chown apache.apache /run/php-fpm
sudo -u apache /usr/sbin/php-fpm

/usr/sbin/httpd
#-DFOREGROUND

export HOME=/tmp/
chmod g+w  /var/spool/nagios/cmd
conf=/etc/nagios/nagios.cfg
/usr/sbin/nagios -v $conf
/usr/sbin/nagios $conf

