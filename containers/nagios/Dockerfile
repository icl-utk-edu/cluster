FROM rockylinux:9

RUN dnf -y install epel-release && \
    dnf -y install nagios httpd mod_ldap sudo && \
    echo tcp nrpe rpc | xargs -n1 | xargs -Iggg dnf -y install nagios-plugins-ggg

COPY nagios.cfg /etc/nagios/
COPY cgi.cfg /etc/nagios/

COPY apache_nagios.conf /etc/httpd/conf.d/
COPY entrypoint.sh /

VOLUME /var/spool/nagios

RUN sed -i 's/listen.acl_users/;/' /etc/php-fpm.d/www.conf


# Configure mail sending
RUN dnf -y install s-nail
RUN echo set v15-compat >> /etc/s-nail.rc
RUN echo set smtp-auth=none >> /etc/s-nail.rc
RUN echo set mta=smtp://mailserver >> /etc/s-nail.rc


# Configure cron job
RUN dnf -y install anacron
COPY cron_nagios_notification_email /opt/
COPY crontab /etc/

ENTRYPOINT /entrypoint.sh


