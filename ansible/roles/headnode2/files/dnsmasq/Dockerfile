FROM centos:7

RUN yum -y install dnsmasq && systemctl enable dnsmasq
COPY dnsmasq.conf /etc/

CMD ["/usr/sbin/dnsmasq", "-d"]

