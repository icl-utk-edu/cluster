FROM almalinux:9

RUN dnf -y update
RUN dnf -y install kernel kernel-core dracut-network rpcbind nfs-utils
#RUN echo 'add_dracutmodules+=" nfs "' > /etc/dracut.conf.d/nfs.conf
RUN dracut --force --add nfs --no-hostonly
RUN chmod 644 /boot/initramfs*.img
RUN dnf -y install readonly-root
RUN ls /lib/modules | xargs -Iggg cp /lib/modules/ggg/vmlinuz /boot/vmlinuz-ggg

RUN dnf -y install openssh-server && \
    systemctl enable sshd && \
    /usr/libexec/openssh/sshd-keygen ecdsa

RUN mkdir /root/.ssh && chmod 700 /root/.ssh

RUN dnf -y install OpenIPMI ipmitool && \
    systemctl enable ipmi
