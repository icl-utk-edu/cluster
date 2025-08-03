FROM rockylinux:9

RUN dnf -y install postfix
COPY main.cf /etc/postfix/

#COPY send_user_verification_emails /root/
#RUN dnf -y install epel-release && \
#    dnf -y install perl-HTML-Template perl-MailTools


CMD /usr/sbin/postfix -v start-fg

