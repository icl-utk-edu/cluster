#!/bin/bash

iptables -P INPUT DROP
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp --icmp-type any -j ACCEPT
iptables -A INPUT -p tcp -s 160.36.131.0/24 --dport 80 -j ACCEPT


mkdir -p /run/php-fpm
/usr/sbin/php-fpm --nodaemonize &

chown ganglia /var/lib/ganglia
/usr/sbin/gmetad -d 1 &

/usr/sbin/httpd -DFOREGROUND

sleep 5
