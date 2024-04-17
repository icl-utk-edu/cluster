FROM rockylinux:9

RUN dnf -y install postfix
COPY main.cf /etc/postfix/
CMD /usr/sbin/postfix -v start-fg

