FROM rockylinux/rockylinux:9

ENV ROLE=EL9

RUN echo "keepcache=1" >> /etc/dnf/dnf.conf

# Reinstall because some files (like man pages) aren't installed at first
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf -y reinstall \* && \
    dnf -y update && \
    dnf -y install readonly-root e2fsprogs
COPY readonly-root /etc/sysconfig/

RUN dnf -y install OpenIPMI ipmitool && \
    systemctl enable ipmi

RUN dnf -y install rsyslog && \
    echo '*.* @headnode' > /etc/rsyslog.d/remote.conf && \
    echo empty /var/lib/rsyslog/ >> /etc/rwtab

INCLUDE ssh

INCLUDE ldapauth

RUN dnf -y install epel-release

INCLUDE slurm

RUN dnf -y install chrony
COPY chrony.conf /etc/

RUN dnf -y install nftables
RUN systemctl enable nftables
COPY nftables.conf /etc/sysconfig/

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf -y group install development debugging infiniband && \
    dnf -y install zsh vim neovim tmux screen man emacs-nox xauth rsync java-11-openjdk sudo \
                   csh zsh sed pciutils gcc-gfortran wget traceroute nmap perl-DBI perl-DBD-SQLite \
                   dmidecode cpuid perf subversion tcpdump net-tools lz4 man-pages colordiff \
                   the_silver_searcher rust smartmontools lsof && \
    dnf -y install --nobest mesa-dri-drivers

INCLUDE kernel

INCLUDE intelGPU

INCLUDE cuda

INCLUDE rocm

INCLUDE zfs

# Build kernel modules
RUN dkms autoinstall -k `cat /boot/kver` && dkms status

# Build initrd
RUN rm -f /boot/initramfs*.img
RUN dracut --force --add nfs --no-hostonly --kver `cat /boot/kver`
RUN chmod 644 /boot/initramfs*.img
RUN ls /lib/modules/*/vmlinuz | xargs -n1 dirname | xargs -n1 basename | xargs -Iggg cp /lib/modules/ggg/vmlinuz /boot/vmlinuz-ggg

RUN rm /etc/NetworkManager/system-connections/* || true

COPY --from=common motd /etc/

ARG MODULE=tcl
RUN if [ "$MODULE" = "tcl" ]; then dnf -y install environment-modules; fi
COPY env-$MODULE.* prompt.sh /etc/profile.d/

INCLUDE docker

COPY rc.local /etc/rc.d/rc.local
RUN systemctl enable rc-local
COPY set_ipoib /usr/local/bin/

#INCLUDE autofs

RUN echo "files /etc/hostname" >> /etc/rwtab
RUN echo "files /var/lib/systemd" >> /etc/rwtab
RUN echo "files /root" >> /etc/rwtab

INCLUDE cron

RUN echo "%admins ALL=(ALL) ALL" > /etc/sudoers.d/admins
RUN echo "%papi guyot,hexane,histamine*,dopamine,serotonin=(ALL) ALL" > /etc/sudoers.d/papi

# Remove memlock limit for MPI
COPY limits.conf /etc/security/

COPY nfs.conf /etc/

INCLUDE ganglia

INCLUDE fail2ban

INCLUDE nagios

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

RUN systemctl disable firewalld

