#!/bin/bash -e

NAME=nfs
cd /opt/$NAME

(
docker stop $NAME
docker rm $NAME
rmmod nfsd
rmmod nfsv4
rmmod nfs
) || true

docker run --name $NAME -d --restart=unless-stopped \
   -v /opt/$NAME/exports:/etc/exports \
   -v /opt/$NAME/exported:/exported \
   -v /lib/modules:/lib/modules:ro \
   --privileged --cap-add SYS_MODULE --cap-add SYS_ADMIN \
   -p 10.0.0.1:2049:2049 \
   erichough/nfs-server > /dev/null 2>&1

echo Done

