sudo yum install nfs-utils -y
sudo systemctl start rpcbind && sudo systemctl enable rpcbind
sudo mkdir /nfs
sudo mount -t nfs -o vers=3 -o proto=udp  192.168.50.10:/shared /nfs
echo "192.168.50.10:/shared /nfs nfs vers=3,proto=udp,noauto,xsystemd.automount 0 0" >> /etc/fstab
