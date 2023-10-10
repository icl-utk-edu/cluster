#!/bin/bash

mkdir -p /run/php-fpm
/usr/sbin/php-fpm --nodaemonize &

chown ganglia /var/lib/ganglia
/usr/sbin/gmetad -d 1 &

/usr/sbin/httpd -DFOREGROUND

sleep 5
