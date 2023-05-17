FROM rockylinux:9

RUN dnf -y update

RUN dnf -y install readonly-root e2fsprogs
COPY readonly-root /etc/sysconfig/

RUN dnf -y install openssh-server && \
    systemctl enable sshd

# Prepare for direct-to-root ssh access
RUN mkdir /root/.ssh && chmod 700 /root/.ssh
COPY sshd_custom.conf /etc/ssh/sshd_config.d/

RUN dnf -y install OpenIPMI ipmitool && \
    systemctl enable ipmi

RUN dnf -y install rsyslog && \
    echo '*.* @headnode' > /etc/rsyslog.d/remote.conf

# Slurm
RUN dnf -y install epel-release && \
    dnf -y install slurm-slurmd munge
RUN systemctl enable munge slurmd
RUN useradd --no-create-home --system -g daemon --uid 9 slurm
COPY --from=munge --chown=munge:munge munge.key /etc/munge/
COPY slurmd.sysconfig /etc/sysconfig/slurmd
RUN rm -f /etc/slurm/slurm.conf


# LDAP for user accounts and authentication
RUN dnf -y install openldap-clients sssd sssd-ldap authselect && \
    systemctl enable sssd
RUN authselect select sssd with-mkhomedir --force
RUN dnf -y install oddjob-mkhomedir
RUN systemctl enable oddjobd
COPY ldap.conf /etc/openldap/
COPY --chmod=0600 sssd.conf /etc/sssd/
COPY --from=common ldapuser_password.txt /tmp/
RUN cat /tmp/ldapuser_password.txt | xargs -Iggg sed -i 's/PASSWORD/ggg/' /etc/sssd/sssd.conf
RUN rm /tmp/ldapuser_password.txt
COPY --from=common ipa-ca.crt /etc/openldap/certs/

RUN dnf -y install chrony
COPY chrony.conf /etc/

RUN dnf -y install nftables
RUN systemctl enable nftables
COPY nftables.conf /etc/sysconfig/

RUN dnf -y group install development debugging
#RUN dnf -y group install infiniband
RUN dnf -y install zsh vim tmux screen man emacs-nox xauth rsync java-11-openjdk sudo

COPY cuda.repo /etc/yum.repos.d/
RUN dnf -y install kmod-nvidia-latest-dkms nvidia-driver-cuda
#nvidia-driver-cuda-libs
#RUN dnf -y install cuda-11-8 kmod-nvidia-latest-dkms
RUN systemctl enable nvidia-persistenced
RUN echo 'options nvidia "NVreg_RestrictProfilingToAdminUsers=0"' > /etc/modprobe.d/nv.conf

COPY rocm.repo /etc/yum.repos.d/
RUN dnf -y install rocm-smi-lib amdgpu-dkms
#RUN dnf -y --enablerepo=crb install perl-File-BaseDir perl-URI-Encode
#RUN dnf -y install amdgpu-dkms rocm-hip-sdk rocm-dkms hip-nvcc rocprim rocm-ml-sdk rocm-openmp-sdk rocm-opencl-sdk rocm-developer-tools rocmtools-dev

RUN dnf -y install https://zfsonlinux.org/epel/zfs-release-2-2$(rpm --eval "%{dist}").noarch.rpm
RUN dnf -y install zfs
RUN mkdir /apps

# Install kernel
RUN dnf -y install kernel kernel-devel dracut-network rpcbind nfs-utils dkms
# Build kernel modules
RUN dkms autoinstall -k `rpm -q kernel | sed 's/kernel-//'` && dkms status
# Build initrd
RUN dracut --force --add nfs --no-hostonly --kver `rpm -q kernel | sed 's/kernel-//'`
RUN chmod 644 /boot/initramfs*.img
RUN ls /lib/modules | xargs -Iggg cp /lib/modules/ggg/vmlinuz /boot/vmlinuz-ggg

#RUN systemctl disable NetworkManager
#RUN echo files /etc/hostname >> /etc/rwtab
RUN rm /etc/NetworkManager/system-connections/*

COPY --from=common motd /etc/

RUN dnf -y install environment-modules
COPY spack.* /etc/profile.d/

COPY docker.repo /etc/yum.repos.d/
RUN dnf -y install docker-ce && \
    systemctl enable docker && \
    mkdir /var/lib/docker /var/lib/containerd && \
    echo empty /var/lib/containerd >> /etc/rwtab
# Nodes that will run docker will have ZFS mounted at /var/lib/docker

COPY rc.local /etc/rc.d/rc.local
RUN systemctl enable rc-local

RUN dnf -y install csh zsh sed
RUN dnf clean all


