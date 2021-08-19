FROM centos:7

RUN yum -y install dnsmasq && systemctl enable dnsmasq
COPY dnsmasq.conf /etc/
RUN mkdir /cluster
COPY pxe /cluster/pxe

CMD ["/usr/sbin/dnsmasq", "-d"]

