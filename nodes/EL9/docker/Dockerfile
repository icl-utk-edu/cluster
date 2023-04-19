FROM almalinux:9

RUN dnf -y update
# Install kernel and initrd
RUN dnf -y install kernel kernel-core dracut-network rpcbind nfs-utils
RUN dracut --force --add nfs --no-hostonly --kver `rpm -q kernel | sed 's/kernel-//'`
RUN chmod 644 /boot/initramfs*.img
RUN ls /lib/modules | xargs -Iggg cp /lib/modules/ggg/vmlinuz /boot/vmlinuz-ggg

RUN dnf -y install readonly-root && \
    echo READONLY=yes >> /etc/sysconfig/readonly-root

RUN dnf -y install openssh-server && \
    systemctl enable sshd

# Prepare for direct-to-root ssh access
RUN mkdir /root/.ssh && chmod 700 /root/.ssh

RUN dnf -y install OpenIPMI ipmitool && \
    systemctl enable ipmi

RUN dnf -y install rsyslog && \
    echo '*.* @headnode' > /etc/rsyslog.d/remote.conf

