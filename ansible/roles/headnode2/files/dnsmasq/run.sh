#!/bin/bash -e

CONF=/opt/cluster/config

NAME=dnsmasq
cd /opt/$NAME

docker stop $NAME || true

if [[ $1 == 'rebuild' ]]; then
   docker build -t $NAME .
fi

NODES=$CONF/dnsmasq-nodes.conf
touch $NODES

docker run --name $NAME -d --rm --restart=unless-stopped \
   --net host \
   -v $NODES:/etc/dnsmasq.d/nodes.conf \
   -v $CONF/pxe:/pxe \
   --privileged \
   $NAME > /dev/null 2>&1

echo Done
