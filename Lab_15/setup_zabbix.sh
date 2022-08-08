
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

dnf install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
dnf module disable mysql
percona-release setup ps80
dnf install percona-server-server percona-toolkit percona-xtrabackup-80
systemctl enable --now mysqld


