FROM rockylinux:8

RUN dnf -y install epel-release
RUN dnf -y install ganglia-web
COPY ganglia.conf /etc/httpd/conf.d/
COPY service.sh /opt/

ENTRYPOINT /opt/service.sh

