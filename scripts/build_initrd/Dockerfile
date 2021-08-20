FROM centos:7

ARG kVer

#RUN yum -y update
#RUN yum -y groupinstall minimal
RUN yum -y install dracut dracut-network dracut-config-generic rpc.statd mount.nfs rpcbind
RUN yum -y install kernel-$kVer
RUN dracut -NM initrd.img $kVer


