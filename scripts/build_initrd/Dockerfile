FROM centos:7

ARG kVer

#RUN yum -y update
#RUN yum -y groupinstall minimal
RUN yum -y install dracut dracut-network dracut-config-generic rpc.statd mount.nfs rpcbind
RUN yum -y install kernel-$kVer

COPY dracut-httproot //usr/lib/dracut/modules.d/90httproot/

RUN dracut -NM initrd.img $kVer


