FROM rockylinux:9

ENV ROLE=EL9

# Reinstall because some files (like man pages) aren't installed at first
RUN dnf -y reinstall \* && dnf -y update

RUN dnf -y install readonly-root e2fsprogs
COPY readonly-root /etc/sysconfig/

RUN dnf -y install openssh-server && \
    systemctl enable sshd
# Prepare for direct-to-root ssh access
RUN ssh-keygen -N '' -f /root/.ssh/id_rsa
COPY sshd_custom.conf /etc/ssh/sshd_config.d/
RUN echo "AllowGroups icl admins root" > /etc/ssh/sshd_config.d/groups.conf
COPY --from=etc ssh/ssh_known_hosts /etc/ssh/
RUN systemctl disable sshd-keygen@ed25519 sshd-keygen@ecdsa
COPY authorized_keys /root/.ssh/authorized_keys
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

RUN dnf -y install OpenIPMI ipmitool && \
    systemctl enable ipmi

RUN dnf -y install rsyslog && \
    echo '*.* @headnode' > /etc/rsyslog.d/remote.conf && \
    echo empty /var/lib/rsyslog/ >> /etc/rwtab


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


# Slurm
RUN dnf -y install epel-release && \
    dnf -y install slurm-slurmd slurm-pam_slurm munge pmix-devel
RUN touch /etc/slurm/gres.conf
RUN echo files /etc/slurm/gres.conf >> /etc/rwtab
COPY --from=etc slurm/slurm.conf slurm/cgroup.conf /etc/slurm/
COPY slurmd.service /usr/lib/systemd/system/
COPY slurmd_startup /usr/sbin/
RUN systemctl enable munge
RUN useradd --no-create-home --system -g daemon --uid 9 slurm
COPY --from=etc --chown=munge:munge munge/munge.key /etc/munge/


RUN dnf -y install chrony
COPY chrony.conf /etc/

RUN dnf -y install nftables
RUN systemctl enable nftables
COPY nftables.conf /etc/sysconfig/

RUN dnf -y group install development debugging infiniband
RUN dnf -y install zsh vim neovim tmux screen man emacs-nox xauth rsync java-11-openjdk sudo

# Install kernel
ARG KERNEL=default
COPY custom.repo vault.repo /etc/yum.repos.d/
COPY kernel.sh /tmp/
RUN /tmp/kernel.sh $KERNEL && rm /tmp/kernel.sh
RUN echo 'excludepkgs=kernel,kernel-devel' >> /etc/dnf/dnf.conf
RUN dnf -y install dracut-network rpcbind nfs-utils NetworkManager


# Install Intel GPU support
COPY intel-gpu.repo /etc/yum.repos.d/
# The intel driver will so far only work with the default OS kernel
RUN if [ $KERNEL = "default" ]; then \
       dnf -y --enablerepo=intel --nobest install intel-fw-gpu intel-i915-dkms xpu-smi \
          intel-opencl intel-media intel-mediasdk libmfxgen1 libvpl2 \
          level-zero intel-level-zero-gpu mesa-dri-drivers mesa-vulkan-drivers \
          mesa-vdpau-drivers mesa-libEGL mesa-libgbm mesa-libGL \
          mesa-libxatracker libvpl-tools intel-metrics-discovery \
          intel-metrics-library intel-igc-core intel-igc-cm \
          libva libva-utils intel-gmmlib libmetee intel-gsc intel-ocloc \
          intel-igc-opencl-devel level-zero-devel intel-gsc-devel libmetee-devel level-zero-devel \
          libdrm hwinfo clinfo intel-ocloc; \
    fi


RUN echo "keepcache=1" >> /etc/dnf/dnf.conf
# Install CUDA
ARG CUDAVER=11
COPY cuda.repo /etc/yum.repos.d/
RUN --mount=type=cache,target=/var/cache/dnf \
    if [ "$KERNEL" == "3" ]; then \
       echo Not installing CUDA ; \
    elif [ $CUDAVER = "11" ]; then \
       dnf -y module install nvidia-driver:545-dkms && \
       dnf -y install cuda-11.8.0 cuda-drivers-fabricmanager-545; \
    elif [ $CUDAVER = "12" ]; then \
       dnf -y install cuda-toolkit-12-8 && \
       dnf -y module install nvidia-driver:565-dkms && \
       dnf -y install nvidia-fabric-manager ; \
       for lib in `find /usr/lib64/libnvidia-*.so.565*`; do \
          ln -s $lib ${lib//\.so\.565*/\.so} ; \
       done ; \
    fi
RUN echo 'options nvidia "NVreg_RestrictProfilingToAdminUsers=0"' > /etc/modprobe.d/nv.conf
RUN if [ "$KERNEL" != "3" ];then systemctl enable nvidia-persistenced; fi

RUN dnf -y install dkms && \
    dkms autoinstall -k `cat /boot/kver`

# Install rocm
COPY rocm.repo /etc/yum.repos.d/
RUN --mount=type=cache,target=/var/cache/dnf \
       if [ "$KERNEL" != "3" ]; then \
       dnf -y --enablerepo=crb install amdgpu-dkms rocm ; \
    fi

#dnf -y --enablerepo=crb install perl-File-BaseDir perl-URI-Encode && \
#rocm-hip-sdk rocm-dkms hip-nvcc rocprim rocm-ml-sdk rocm-openmp-sdk rocm-opencl-sdk rocm-developer-tools ; \

RUN dnf -y install https://zfsonlinux.org/epel/zfs-release-2-2$(rpm --eval "%{dist}").noarch.rpm
RUN dnf -y install zfs
RUN mkdir -p /apps /data

# Build kernel modules
RUN dkms autoinstall -k `cat /boot/kver` && dkms status

# Build initrd
RUN dracut --force --add nfs --no-hostonly --kver `cat /boot/kver`
RUN chmod 644 /boot/initramfs*.img
RUN ls /lib/modules | xargs -Iggg cp /lib/modules/ggg/vmlinuz /boot/vmlinuz-ggg

RUN rm /etc/NetworkManager/system-connections/*

COPY --from=common motd /etc/

ARG MODULE=tcl
RUN dnf -y install environment-modules
COPY env-$MODULE.* prompt.sh /etc/profile.d/

COPY docker.repo /etc/yum.repos.d/
RUN groupadd -g 1001 docker
RUN dnf -y install docker-ce && \
    mkdir /var/lib/docker /var/lib/containerd && \
    echo empty /var/lib/containerd >> /etc/rwtab
COPY docker-daemon.json /etc/docker/daemon.json
    # Docker and containerd are started by rc.local

COPY rc.local /etc/rc.d/rc.local
RUN systemctl enable rc-local
COPY set_ipoib /usr/local/bin/

#RUN dnf -y install autofs && \
#    systemctl enable autofs && \
#    rm -rf /etc/auto.* && \
#    echo "/nfs /etc/auto.nfs" > /etc/auto.master && \
#    mkdir -p /nfs
#COPY auto.nfs /etc/

RUN echo "files /etc/hostname" >> /etc/rwtab
RUN echo "files /var/lib/systemd" >> /etc/rwtab
RUN echo "files /root" >> /etc/rwtab

RUN dnf -y install csh zsh sed pciutils gcc-gfortran wget traceroute nmap perl-DBI perl-DBD-SQLite dmidecode cpuid perf subversion
RUN dnf -y install --nobest mesa-dri-drivers

RUN dnf -y install cronie && \
    rm -f /etc/cron.deny
RUN wget -O - https://github.com/zfsonlinux/zfs-auto-snapshot/archive/upstream/1.2.4.tar.gz | tar -zx && \
    cd zfs-auto-snapshot* && \
    make install && \
    cd .. && rm -rf zfs-auto-snapshot* && \
    ln -s /usr/local/sbin/zfs-auto-snapshot /usr/sbin/ && \
    rm /etc/cron.monthly/zfs-auto-snapshot && \
    sed -i 's/\/\//mnt\/apps mnt\/home/' /etc/cron.*/zfs-auto-snapshot
COPY cron.d /etc/cron.d

RUN echo "%admins ALL=(ALL) ALL" > /etc/sudoers.d/admins
RUN echo "%papi dopamine,serotonin=(ALL) ALL" > /etc/sudoers.d/papi

# Remove memlock limit for MPI
COPY limits.conf /etc/security/

COPY nfs.conf /etc/

# Ganglia
RUN dnf -y install ganglia-gmond && \
    systemctl enable gmond
COPY gmond.conf /etc/ganglia/


# Nagios
RUN echo swap load perl \
    | xargs -n1 | xargs -Iggg echo nagios-plugins-ggg | xargs dnf -y install nrpe
# Disable nrpe because systemd causes it to not work correctly.  Start in rc.local.
RUN systemctl disable nrpe
COPY nrpe.cfg /etc/nagios/
COPY nrpe_plugins /etc/nagios/plugins
RUN echo "nrpe ALL = (root) NOPASSWD: /etc/nagios/plugins/check_temperature" > /etc/sudoers.d/nrpe


COPY inventory.sh /etc/cron.daily/
RUN echo "files /etc/cron.daily/inventory.sh" >> /etc/rwtab

RUN dnf -y install tcpdump net-tools lz4 man-pages colordiff the_silver_searcher rust smartmontools lsof
RUN dnf clean all

ARG HASH
COPY config.ipxe /boot/
RUN if [ "$KERNEL" == "3" ]; then \
       sed -i "s/EL9/EL7/" /boot/config.ipxe && \
       sed -i "s/HASH/f3497004c9a4d9e7e862da9859f42667/" /boot/config.ipxe && \
       sed -i "s/HASH/$HASH/" /boot/config.ipxe ; \
    else \
       sed -i "s/HASH/$HASH/g" /boot/config.ipxe ; \
    fi

# Enable old core dump behavior
RUN echo kernel.core_pattern=core > /etc/sysctl.d/99-coredump.conf

# SSH keys
COPY --from=etc --chmod=0600 ssh/ssh_host_rsa_key /etc/ssh/
COPY --from=ssh_root id_rsa.pub /root/.ssh/authorized_keys
COPY authorized_keys /tmp/
RUN cat /tmp/authorized_keys >> /root/.ssh/authorized_keys && \
    rm /tmp/authorized_keys

# Slurm PAM adopt config
RUN touch /etc/pam.d/slurm
RUN echo "files /etc/pam.d/slurm" >> /etc/rwtab  # slurmd_startup writes here
COPY pam.d-password-auth /etc/pam.d/password-auth
#RUN sed -i -e '/systemd/ s/^#*/#/' /etc/pam.d/* /etc/authselect/*-auth


# Fail2ban
RUN dnf -y install fail2ban
COPY jail.local /etc/fail2ban/
COPY fail2ban /etc/rc.d/rc3.d/

