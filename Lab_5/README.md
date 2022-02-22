# Лабораторная работа №5.  Vagrant стенд для NFS.

## Настройка окружения

* Использовался образ **centos/7** версии 2004.01

## Порядок работы

### 1. Создание и настройка виртуальных машин сервера и клиента NFS 
* создаем [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_5/Vagrantfile) описывающий VM сервера и клиента, ссылающийся на скрипты начальной настройки [nfss_script.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_5/nfss_script.sh) и [nfsс_script.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_5/nfsс_script.sh) соответственно
```
sudo yum install nfs-utils nfs-utils-lib -y
sudo systemctl start firewalld && sudo systemctl enable firewalld
sudo firewall-cmd --permanent --zone=public --add-service=nfs && sudo firewall-cmd --permanent --zone=public --add-service=mountd &&  sudo firewall-cmd --permanent --zone=public --add-service=rpc-bind  && sudo firewall-cmd --permanent --add-port=2049/udp --zone=public && sudo firewall-cmd --reload 
sudo mkdir /shared  && sudo mkdir /shared/upload
sudo chown -R nfsnobody:nfsnobody /shared && sudo chmod -R 777 /shared
echo -e "/shared 192.168.50.11(rw,sync,no_root_squash)" | sudo tee --append /etc/exports
sudo systemctl enable rpcbind nfs-server
sudo systemctl start rpcbind nfs-server                                                         
```
```
sudo yum install nfs-utils -y
sudo systemctl start rpcbind && sudo systemctl enable rpcbind
sudo mkdir /nfs
sudo mount -t nfs -o vers=3 -o proto=udp  192.168.50.10:/shared /nfs
echo "192.168.50.10:/shared  /nfs nfs vers=3,proto=udp,noauto,xsystemd.automount 0 0" >> /etc/fstab
```
* проверяем после завершения выполнения команды **vagrant up**
```
[root@nfss ~]# exportfs -s
/shared  192.168.50.11(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
```
```
[root@nfsc ~]# mount | grep /shared
192.168.50.10:/shared on /nfs type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
```
  
### 2. Проверка работоспособности
* проверяем появление файла **check_file** на клиенте после создания его на сервере
```
[root@nfss ~]# touch /shared/upload/check_file
```
```
[root@nfsc ~]# ll /nfs/upload
total 0
-rw-r--r--. 1 root root 0 Feb 22 05:54 check_file
```
* перезагружаем клиент, смотрим, на месте ли файл **check_file**
```
[root@nfsc ~]# ll /nfs/upload
total 0
-rw-r--r--. 1 root root 0 Feb 22 05:54 check_file
```
* перезагружаем сервер, смотрим, на месте ли файл **check_file**
```
[root@nfss ~]# ll /shared/upload
total 0
-rw-r--r--. 1 root root 0 Feb 22 05:54 check_file

```
* проверяем статус сервера NFS
```
[root@nfss ~]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Tue 2022-02-22 06:09:15 UTC; 2min 13s ago
  Process: 778 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 755 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 753 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 755 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Feb 22 06:09:15 nfss systemd[1]: Starting NFS server and services...
Feb 22 06:09:15 nfss systemd[1]: Started NFS server and services.
```
* проверяем статус firewall
```
[root@nfss ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2022-02-22 06:09:05 UTC; 3min 52s ago
     Docs: man:firewalld(1)
 Main PID: 368 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─368 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 22 06:09:00 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Feb 22 06:09:05 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
```
* проверяем экспорты
```
[root@nfss ~]# exportfs -s
/shared  192.168.50.11(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
```
* проверяем работу RPC
```
[root@nfss ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/shared
```
* перезагружаем клиент, проверяем работу RPC
```
[root@nfsc nfs]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/shared
```
* проверяем статус монтирования
```
[root@nfsc nfs]# mount | grep nfs
sunrpc on /var/lib/nfs/rpc_pipefs type rpc_pipefs (rw,relatime)
192.168.50.10:/shared on /nfs type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
```
* проверяем наличие файла **check_file**
```
[root@nfsc ~]# ll /nfs/upload
total 0
-rw-r--r--. 1 root root 0 Feb 22 05:54 check_file
```
* создаём тестовый файл **final_check**, проверяем, что создался
```
[root@nfsc ~]# touch /nfs/upload/final_check
[root@nfsc ~]# ll /nfs/upload
total 0
-rw-r--r--. 1 root root 0 Feb 22 05:54 check_file
-rw-r--r--. 1 root root 0 Feb 22 06:52 final_check
```
* вывод - тестовый стенд NFS работоспособен

## Результат работы

* В репозиторий GitHUB добавлен [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_5/Vagrantfile), а так же скрипты начальной настройки сервера и клиента NFS [nfss_script.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_5/nfss_script.sh) и [nfsс_script.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_5/nfsс_script.sh) соответственно , на которые есть ссылки в [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_5/Vagrantfile)
* В репозиторий GitHUB добавлено описание [README.md](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_5/README.md)

