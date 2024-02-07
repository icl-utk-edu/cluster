#!/bin/bash -e

NAME=https

docker build -t $NAME .

docker rm -f $NAME || true

docker run --name $NAME \
   -h headnode.icl.utk.edu \
   -d --restart=unless-stopped \
   -v certificate:/etc/letsencrypt \
   -v `pwd`/DocumentRoot:/var/www/html \
   -p 80:80 \
   -p 443:443 \
   $NAME

