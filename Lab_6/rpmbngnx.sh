sudo su && cd /root
yum install  redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc -y
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1m.tar.gz
tar -xvf openssl-1.1.1m.tar.gz
mv /root/rpmbuild/SPECS/nginx.spec /root/rpmbuild/SPECS/nginx.spec."$(date +%d-%m-%Y.%H.%M)" && cp /home/vagrant/nginx.spec /root/rpmbuild/SPECS/nginx.spec
yum-builddep rpmbuild/SPECS/nginx.spec -y
rpmbuild -bb rpmbuild/SPECS/nginx.spec
yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
systemctl start nginx
mkdir /usr/share/nginx/html/repo
cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-27/redhat/percona-release-1.0-27.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-27.noarch.rpm
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf."$(date +%d-%m-%Y.%H.%M)" && cp /home/vagrant/default.conf /etc/nginx/conf.d/default.conf
echo -e "[otus]\nname=otus-linux\nbaseurl=http://localhost/repo\ngpgcheck=0\nenabled=1\n" >  /etc/yum.repos.d/otus.repo
nginx -s reload
createrepo /usr/share/nginx/html/repo/
yum install percona-release -y

