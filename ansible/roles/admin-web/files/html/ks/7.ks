
auth --enableshadow --passalgo=sha512
url --url http://mirrors.rit.edu/centos/7/os/x86_64
text
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

rootpw --iscrypted $6$LNOsjwwTy1YVc2mN$uNDcEpza1h0szhW2k.Am0TNtg6bddKkSGh0DNcIokS8raEwseJsFQJ9syJ7yXgFz.T6dCScgxc4Dia/x/UX/U/
timezone America/New_York
#bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
autopart --type=lvm
clearpart --all --initlabel
ignoredisk --only-use=sda
reboot


%packages
@^minimal
@core
@base
#chrony
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=50 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=50 --notstrict --nochanges --notempty
pwpolicy luks --minlen=6 --minquality=50 --notstrict --nochanges --notempty
%end

%post
mkdir /root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqhiZLnGIfqt8G1D49r8JOwIIYNkdbTtXbrzpLreDSGv9rpuCTlPcvWjZ9pgSI0iQo+i5UP6qr4JcEb4oK8jHuS73rj/IfoL+mRzreyJBxIockBhmAd68Oznf5gT6ZpmepFA3VpxzHOd1MU/4GDWkA//J4TPsHq6YuyrcI+yc+SiXx4gcYN8iYGCcYnFhbemgeHW60Og65TZsisXhLD7GncFM1FPzf12vasbgYGgxJv6n+VNcKIFy58eQsJxtfzkIjICjhVxRwDqa+89eVAiODnnq6KmZQXzkJahayYw43dcdeMOksr+QgFEJ+aYl4mYkltEB5dRu1KLKAfHeYDoG5 Administrator" > /root/.ssh/authorized_keys
yum -y update
%end

