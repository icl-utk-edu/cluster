#!/bin/bash -e

NAME=dnsmasq
cd /opt/$NAME

docker stop $NAME || true
docker rm $NAME   || true

if [[ $1 == 'rebuild' ]]; then
   docker build -t $NAME .
fi

docker run --name $NAME -d --restart=unless-stopped \
   --net host \
   -v /opt/$NAME/dnsmasq.conf:/etc/dnsmasq.conf \
   -v /opt/$NAME/nodes.conf:/etc/dnsmasq.d/nodes.conf \
   --privileged \
   $NAME > /dev/null 2>&1

echo Done

#   -p 53:53/udp \
#   -p 67:67/udp \
#   -p 69:69/udp \
