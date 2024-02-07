FROM rockylinux:9

RUN dnf -y install epel-release
RUN dnf -y install httpd mod_ssl certbot python3-certbot-apache
RUN dnf -y install perl-CGI perl-JSON
RUN rm /etc/httpd/conf.d/welcome.conf
COPY httpd.conf /etc/httpd/conf.d/custom.conf
RUN openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj \
    "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname" && \
    mv key.pem /etc/pki/tls/private/localhost.key && \
    mv cert.pem /etc/pki/tls/certs/localhost.crt

# certbot uses "apachectl"
COPY apachectl /usr/sbin/

COPY entrypoint.sh /opt/
ENTRYPOINT /opt/entrypoint.sh

