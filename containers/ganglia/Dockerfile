FROM rockylinux:8

RUN dnf -y install epel-release
RUN dnf -y install ganglia-gmetad ganglia-web
RUN dnf -y install iptables
COPY gmetad.conf /etc/ganglia/
COPY ganglia.conf /etc/httpd/conf.d/
COPY service.sh /opt/

ENTRYPOINT /opt/service.sh


