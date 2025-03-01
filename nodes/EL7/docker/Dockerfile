FROM centos:7

RUN rm -f /etc/yum.repos.d/*.repo
COPY vault.repo /etc/yum.repos.d/

# Reinstall because some files (like man pages) aren't installed at first
RUN yum -y reinstall \*

RUN rm -f /etc/yum.repos.d/*.repo
COPY vault.repo /etc/yum.repos.d/

RUN yum -y install e2fsprogs initscripts

RUN yum -y group install development
RUN yum -y group install debugging
RUN yum -y group install infiniband
#RUN yum -y install epel-release zsh vim tmux screen man emacs-nox xauth rsync java-11-openjdk sudo

# Install kernel
RUN yum -y install kernel kernel-devel
RUN rpm -q kernel | sed -e s/kernel-// > /boot/kver
RUN yum -y install wget && \
    wget https://vault.centos.org/7.9.2009/extras/x86_64/Packages/epel-release-7-11.noarch.rpm && \
    rpm -iv epel-release-7-11.noarch.rpm
RUN yum -y install dracut-network rpcbind nfs-utils dkms NetworkManager

# Build kernel modules
RUN dkms autoinstall -k `cat /boot/kver` && dkms status
# Build initrd
RUN dracut --force --add nfs --no-hostonly --kver `cat /boot/kver`
RUN chmod 644 /boot/initramfs*.img

#RUN mkdir /root/.ssh && touch /root/.ssh/authorized_keys

RUN yum clean all


