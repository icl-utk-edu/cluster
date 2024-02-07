#!/bin/sh

httpd

certbot --apache -m operations@icl.utk.edu --agree-tos -n --domains `hostname`

while true; do
	certbot renew
	sleep 7d
done

