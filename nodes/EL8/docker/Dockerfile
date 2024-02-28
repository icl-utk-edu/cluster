FROM rockylinux:8

# Reinstall because some files (like man pages) aren't installed at first
RUN dnf -y reinstall \* && dnf -y update

#RUN dnf -y install readonly-root e2fsprogs
#COPY readonly-root /etc/sysconfig/

RUN dnf -y install openssh-server && \
    systemctl enable sshd

# Prepare for direct-to-root ssh access
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

RUN dnf -y install OpenIPMI ipmitool && \
    systemctl enable ipmi

RUN dnf -y install rsyslog && \
    echo '*.* @headnode' > /etc/rsyslog.d/remote.conf && \
    echo empty /var/lib/rsyslog/ >> /etc/rwtab

RUN dnf -y install nftables
RUN systemctl enable nftables
COPY nftables.conf /etc/sysconfig/

#RUN dnf -y group install development debugging

RUN dnf -y install https://repo.download.nvidia.com/baseos/el/el-files/8/nvidia-repo-setup-21.06-1.el8.x86_64.rpm
RUN dnf -y group install -y 'DGX A100 Configurations'
RUN dnf module install -y nvidia-driver:470/{fm,src}
RUN dnf install -y nv-persistence-mode nvidia-fm-enable nvidia-conf-xconfig nv-docker-gpus
RUN which nvsm

RUN dnf -y install epel-release

# Install kernel
RUN dnf -y install kernel kernel-devel dracut-network rpcbind nfs-utils dkms NetworkManager

COPY rc.local /etc/rc.d/rc.local
RUN systemctl enable rc-local

RUN echo "files /var/lib/systemd" >> /etc/rwtab
RUN echo "files /root" >> /etc/rwtab

RUN dnf -y install vim csh zsh sed pciutils gcc-gfortran wget dmidecode rsync openssh-clients

RUN /usr/libexec/openssh/sshd-keygen rsa

RUN echo SELINUX=disabled > /etc/selinux/config


# Build kernel modules
RUN dkms autoinstall -k `rpm -q kernel | sed 's/kernel-//'` && dkms status
# Build initrd
RUN dracut --force --add nfs --no-hostonly --kver `rpm -q kernel | sed 's/kernel-//'`
RUN chmod 644 /boot/initramfs*.img
RUN ls /lib/modules | xargs -Iggg cp /lib/modules/ggg/vmlinuz /boot/vmlinuz-ggg


RUN dnf clean all
