FROM rockylinux:9

RUN dnf -y update

RUN dnf -y install readonly-root && \
    echo READONLY=yes >> /etc/sysconfig/readonly-root

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
RUN systemctl enable slurmd munge
RUN useradd --no-create-home --system -g daemon --uid 9 slurm
COPY --from=munge --chown=munge:munge munge.key /etc/munge/
COPY --from=slurm slurm.conf /etc/slurm/
COPY --from=slurm nodes.conf /etc/slurm/
COPY --from=slurm partitions.conf /etc/slurm/

RUN systemctl disable NetworkManager

# LDAP for user accounts and authentication
RUN dnf -y install openldap-clients sssd sssd-ldap authselect && \
    systemctl enable sssd
RUN authselect select sssd --force
COPY ldap.conf /etc/openldap/
COPY --chmod=0600 sssd.conf /etc/sssd/
COPY --from=common ldapuser_password.txt /tmp/
RUN cat /tmp/ldapuser_password.txt | xargs -Iggg sed -i 's/PASSWORD/ggg/' /etc/sssd/sssd.conf
RUN rm /tmp/ldapuser_password.txt
COPY --from=common ipa-ca.crt /etc/openldap/certs/

RUN dnf -y install chrony
COPY chrony.conf /etc/

RUN dnf -y install vim screen man

RUN dnf -y install nftables
RUN systemctl enable nftables
COPY nftables.conf /etc/sysconfig/

RUN dnf -y group install development infiniband debugging
RUN dnf -y install bind-utils binutils-devel emacs-nox git hmaccalc hwloc ipmitool java-11-openjdk mercurial ncurses-devel numactl numactl-devel OpenIPMI pcp-libs-devel perl-DBD-SQLite psmisc readline-devel rsync screen tcl tigervnc tmux vim vim-X11 xauth zlib-devel zsh

COPY cuda.repo /etc/yum.repos.d/
RUN dnf -y install cuda-11-8 kmod-nvidia-latest-dkms
RUN systemctl enable nvidia-persistenced
RUN echo 'options nvidia "NVreg_RestrictProfilingToAdminUsers=0"' > /etc/modprobe.d/nv.conf

COPY rocm.repo /etc/yum.repos.d/
RUN dnf -y --enablerepo=crb install perl-File-BaseDir perl-URI-Encode
RUN dnf -y install amdgpu-dkms rocm-hip-sdk rocm-dkms hip-nvcc rocprim rocm-ml-sdk rocm-openmp-sdk rocm-opencl-sdk rocm-developer-tools rocmtools-dev

# Install kernel
RUN dnf -y install kernel kernel-devel dracut-network rpcbind nfs-utils
# Build kernel modules
RUN dkms autoinstall && dkms status
# Build initrd
RUN dracut --force --add nfs --no-hostonly --kver `rpm -q kernel | sed 's/kernel-//'`
RUN chmod 644 /boot/initramfs*.img
RUN ls /lib/modules | xargs -Iggg cp /lib/modules/ggg/vmlinuz /boot/vmlinuz-ggg

COPY --from=common motd /etc/

RUN dnf clean all


