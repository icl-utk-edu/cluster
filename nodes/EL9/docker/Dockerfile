FROM rockylinux:9

RUN dnf -y update
# Install kernel and initrd
RUN dnf -y install kernel dracut-network rpcbind nfs-utils
RUN dracut --force --add nfs --no-hostonly --kver `rpm -q kernel | sed 's/kernel-//'`
RUN chmod 644 /boot/initramfs*.img
RUN ls /lib/modules | xargs -Iggg cp /lib/modules/ggg/vmlinuz /boot/vmlinuz-ggg

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

RUN dnf clean all


