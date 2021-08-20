#!/bin/bash -e

NAME=dnsmasq
cd /opt/$NAME

docker stop $NAME || true

if [[ $1 == 'rebuild' ]]; then
   docker build -t $NAME .
fi

CONF=/opt/cluster/config
mkdir -p $CONF
cp -a /opt/$NAME/pxe $CONF/
NODES=$CONF/dnsmasq-nodes.conf
touch $NODES

docker run --name $NAME -d --rm --restart=unless-stopped \
   --net host \
   -v $NODES:/etc/dnsmasq.d/nodes.conf \
   -v $CONF/pxe:/pxe \
   --privileged \
   $NAME > /dev/null 2>&1

echo Done
