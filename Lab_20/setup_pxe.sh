#!/bin/bash

echo "***********************************************************************"
echo "***********Provision script on "$(hostname)
echo "***********************************************************************"
echo Install PXE server

mkfs.xfs /dev/sdb
mkdir /mnt/extraspace
mount /dev/sdb /mnt/extraspace
chown vagrant.vagrant  /mnt/extraspace

sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

yum -y install epel-release
yum -y install dhcp-server
yum -y install tftp-server
yum -y install nginx
yum -y install wget

firewall-cmd --add-service=tftp
# disable selinux or permissive
setenforce 0

cat >/etc/dhcp/dhcpd.conf <<EOF
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;

subnet 10.0.0.0 netmask 255.255.255.0 {
        #option routers 10.0.0.254;
        range 10.0.0.100 10.0.0.120;

        class "pxeclients" {
          match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
          next-server 10.0.0.20;

          if option architecture-type = 00:07 {
            filename "uefi/shim.efi";
            } else {
            filename "pxelinux/pxelinux.0";
          }
        }
}
EOF
systemctl start dhcpd

systemctl start tftp.service
yum -y install syslinux-tftpboot.noarch
mkdir /var/lib/tftpboot/pxelinux
cp /tftpboot/pxelinux.0 /var/lib/tftpboot/pxelinux
cp /tftpboot/libutil.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/menu.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/libmenu.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/ldlinux.c32 /var/lib/tftpboot/pxelinux
cp /tftpboot/vesamenu.c32 /var/lib/tftpboot/pxelinux

mkdir /var/lib/tftpboot/pxelinux/pxelinux.cfg

cat >/var/lib/tftpboot/pxelinux/pxelinux.cfg/default <<EOF
default menu
prompt 0
timeout 600

MENU TITLE Demo PXE setup

LABEL linux
  menu label ^Install system
  menu default
  kernel images/CentOS-8.4/vmlinuz
  append initrd=images/CentOS-8.4/initrd.img ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8-install
LABEL linux-auto
  menu label ^Auto install system
  kernel images/CentOS-8.4/vmlinuz
  append initrd=images/CentOS-8.4/initrd.img ip=enp0s3:dhcp inst.repo=http://10.0.0.20/centos8-install inst.ks=http://10.0.0.20/ks.cfg
LABEL vesa
  menu label Install system with ^basic video driver
  kernel images/CentOS-8.4/vmlinuz
  append initrd=images/CentOS-8.4/initrd.img ip=dhcp inst.xdriver=vesa nomodeset
LABEL rescue
  menu label ^Rescue installed system
  kernel images/CentOS-8.4/vmlinuz
  append initrd=images/CentOS-8.4/initrd.img rescue
LABEL local
  menu label Boot from ^local drive
  localboot 0xffff
EOF

mkdir -p /var/lib/tftpboot/pxelinux/images/CentOS-8.4/
wget --progress=bar:force:noscroll --no-check-certificate https://mirror.sale-dedic.com/centos/8.4.2105/BaseOS/x86_64/os/images/pxeboot/initrd.img
wget --progress=bar:force:noscroll --no-check-certificate https://mirror.sale-dedic.com/centos/8.4.2105/BaseOS/x86_64/os/images/pxeboot/vmlinuz
cp {vmlinuz,initrd.img} /var/lib/tftpboot/pxelinux/images/CentOS-8.4/
wget --progress=bar:force:noscroll --no-check-certificate -O /mnt/extraspace/CentOS-8.4.2105-x86_64-dvd1.iso https://mirror.sale-dedic.com/centos/8.4.2105/isos/x86_64/CentOS-8.4.2105-x86_64-dvd1.iso 
mkdir /mnt/centos8-install
mount -t iso9660 /mnt/extraspace/CentOS-8.4.2105-x86_64-dvd1.iso /mnt/centos8-install

sed -i 's#/usr/share/nginx/html#/mnt#' /etc/nginx/nginx.conf
systemctl start nginx.service
systemctl enable nginx.service

autoinstall(){
cat > /mnt/ks.cfg <<EOF
#version=RHEL8
ignoredisk --only-use=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel --drives=sda
# Use graphical install
graphical
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=enp0s3 --ipv6=auto --activate
network  --bootproto=dhcp --device=enp0s8 --onboot=off --ipv6=auto --activate
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted $6$g4WYvaAf1mNKnqjY$w2MtZxP/Yj6MYQOhPXS2rJlYT200DcBQC5KGWQ8gG32zASYYLUzoONIYVdRAr4tu/GbtB48.dkif.1f25pqeh.
# Run the Setup Agent on first boot
firstboot --enable
# Do not configure the X Window System
skipx
# System services
services --enabled="chronyd"
# System timezone
timezone America/New_York --isUtc
user --groups=wheel --name=val --password=$6$ihX1bMEoO3TxaCiL$OBDSCuY.EpqPmkFmMPVvI3JZlCVRfC4Nw6oUoPG0RGuq2g5BjQBKNboPjM44.0lJGBc7OdWlL17B3qzgHX2v// --iscrypted --gecos="val"

%packages
@^minimal-environment
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

EOF
}
autoinstall
