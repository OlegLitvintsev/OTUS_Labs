# Лабораторная работа № 22. **OSPF**

## Задание: Настраиваем OSPF

- Поднять три виртуальные машины
- Объединить их разными vlan
- Поднять **OSPF** между машинами
- Изобразить ассиметричный роутинг
- Сделать один из линков "дорогим", но что бы при этом роутинг был симметричным

## Решение

* Cхема сетевого взаимодействия узлов (маршрутизаторов) стенда

![схема сети](/Lab_22/imgs/ospf.png)

* В репозиторий **GitHUB** добавлен [Vagrant файл](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_22/Vagrantfile),  который  разворачивает требуемый стенд из 3 виртуальных машин

### Описание действий для автонастройки стенда 

* В **Vagrantfile** для каждой станции на интерфейсах выставляются адреса согласно схемы. Везде устанавливаются сетевые настройки ядра, такие как включение ```ip_forward``` и отключение ```rp_filter```. На каждом хосте устанавливается **Quagga** с заранее подготовленными конфигурационными файлами ```zebra.conf``` и ```ospfd.conf```

## Проверка работы стенда

* На **R1** осуществляется вывод адресов сетевых интерфейсов и схема маршрутизации. Также выполняется трассировка пакета до не связанного напрямую с **R1** интерфейса на роутере **R3**, который проходит по кратчайшему пути.
```
[vagrant@r1 ~]$ sudo su -l
[root@r1 ~]# ip -c a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 85583sec preferred_lft 85583sec
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:91:c5:61 brd ff:ff:ff:ff:ff:ff
    inet 10.1.0.1/30 brd 10.1.0.3 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:13:2f:cc brd ff:ff:ff:ff:ff:ff
    inet 10.10.0.1/30 brd 10.10.0.3 scope global noprefixroute eth2
       valid_lft forever preferred_lft forever
[root@r1 ~]# ip ro
default via 10.0.2.2 dev eth0 proto dhcp metric 101
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101
10.1.0.0/30 dev eth1 proto kernel scope link src 10.1.0.1 metric 100
10.10.0.0/30 dev eth2 proto kernel scope link src 10.10.0.1 metric 102
10.20.0.0/30 proto zebra metric 200
        nexthop via 10.1.0.2 dev eth1 weight 1
        nexthop via 10.10.0.2 dev eth2 weight 1
[root@r1 ~]# tracepath 10.20.0.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.20.0.1                                             3.279ms reached
 1:  10.20.0.1                                             1.409ms reached
     Resume: pmtu 1500 hops 1 back 1
```
* На **R1** увеличивается стоимость (```cost```) линка до **R3**. При выполнении трассировки до того же не связанного напрямую с **R1** интерфейса на роутере **R3**, видно что пакет идет по ***обходному*** маршруту за 2 хопа.
```
[root@r1 ~]# cat /etc/quagga/ospfd.conf
!
hostname r1
password zebra
log file /var/log/quagga/ospfd.log
log stdout
!
!
interface eth1
 ip ospf mtu-ignore
 ip ospf network point-to-point
 ip ospf hello-interval 5
 ip ospf dead-interval 10
 ip ospf cost 100
!
interface eth2
 ip ospf mtu-ignore
 ip ospf network point-to-point
 ip ospf hello-interval 5
 ip ospf dead-interval 10
 ip ospf cost 100
!
router ospf
 ospf router-id 1.1.1.1
 network 10.1.0.0/30 area 0.0.0.0
 network 10.10.0.0/30 area 0.0.0.0
!
default-information originate always
!
line vty
!
[root@r1 ~]# vi /etc/quagga/ospfd.conf
[root@r1 ~]# cat /etc/quagga/ospfd.conf
!
hostname r1
password zebra
log file /var/log/quagga/ospfd.log
log stdout
!
!
interface eth1
 ip ospf mtu-ignore
 ip ospf network point-to-point
 ip ospf hello-interval 5
 ip ospf dead-interval 10
 ip ospf cost 100
!
interface eth2
 ip ospf mtu-ignore
 ip ospf network point-to-point
 ip ospf hello-interval 5
 ip ospf dead-interval 10
 ip ospf cost 200
!
router ospf
 ospf router-id 1.1.1.1
 network 10.1.0.0/30 area 0.0.0.0
 network 10.10.0.0/30 area 0.0.0.0
!
default-information originate always
!
line vty
!
[root@r1 ~]# systemctl restart zebra ospfd
[root@r1 ~]# ip ro
default via 10.0.2.2 dev eth0 proto dhcp metric 101
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101
10.1.0.0/30 dev eth1 proto kernel scope link src 10.1.0.1 metric 100
10.10.0.0/30 dev eth2 proto kernel scope link src 10.10.0.1 metric 102
10.20.0.0/30 via 10.1.0.2 dev eth1 proto zebra metric 200
[root@r1 ~]# tracepath 10.20.0.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.1.0.2                                              1.450ms
 1:  10.1.0.2                                              1.437ms
 2:  10.20.0.1                                             2.153ms reached
     Resume: pmtu 1500 hops 2 back 1
```
* На **R3** осуществляется вывод адресов сетевых интерфейсов и схемы маршрутизации. Так же как и на **R1** выполняется трассировка пакета до не связанного напрямую с **R3** интерфейса на роутере **R1**, который также возвращается с другого интерфейса по обходному маршруту. 
```
[vagrant@r3 ~]$ sudo su -l
[root@r3 ~]# ip -c a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 85594sec preferred_lft 85594sec
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:82:fc:3f brd ff:ff:ff:ff:ff:ff
    inet 10.20.0.1/30 brd 10.20.0.3 scope global eth1
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:bd:0a:f1 brd ff:ff:ff:ff:ff:ff
    inet 10.10.0.2/30 brd 10.10.0.3 scope global noprefixroute eth2
       valid_lft forever preferred_lft forever
[root@r3 ~]# ip ro
default via 10.0.2.2 dev eth0 proto dhcp metric 101
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101
10.1.0.0/30 proto zebra metric 200
        nexthop via 10.20.0.2 dev eth1 weight 1
        nexthop via 10.10.0.1 dev eth2 weight 1
10.10.0.0/30 dev eth2 proto kernel scope link src 10.10.0.2 metric 102
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1 metric 100
[root@r3 ~]# tracepath 10.1.0.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.20.0.2                                             1.987ms
 1:  10.20.0.2                                             4.277ms
 2:  10.1.0.1                                              3.997ms reached
     Resume: pmtu 1500 hops 2 back 2
```
* Для возвращения ***симметричности*** роутинга выставляется аналогичная стоимость на другом линке. Снова выполняется трассировка пакета до **R1**  и в этот раз он уже проходит по кратчайшему маршруту. 
```
[root@r3 ~]# cat /etc/quagga/ospfd.conf
!
hostname r3
password zebra
log file /var/log/quagga/ospfd.log
log stdout
!
!
interface eth1
 ip ospf mtu-ignore
 ip ospf network point-to-point
 ip ospf hello-interval 5
 ip ospf dead-interval 10
 ip ospf cost 100
!
interface eth2
 ip ospf mtu-ignore
 ip ospf network point-to-point
 ip ospf hello-interval 5
 ip ospf dead-interval 10
 ip ospf cost 100
!
router ospf
 ospf router-id 3.3.3.3
 network 10.10.0.0/30 area 0.0.0.0
 network 10.20.0.0/30 area 0.0.0.0
!
default-information originate always
!
line vty
!
[root@r3 ~]# vi /etc/quagga/ospfd.conf
[root@r3 ~]# cat /etc/quagga/ospfd.conf
!
hostname r3
password zebra
log file /var/log/quagga/ospfd.log
log stdout
!
!
interface eth1
 ip ospf mtu-ignore
 ip ospf network point-to-point
 ip ospf hello-interval 5
 ip ospf dead-interval 10
 ip ospf cost 200
!
interface eth2
 ip ospf mtu-ignore
 ip ospf network point-to-point
 ip ospf hello-interval 5
 ip ospf dead-interval 10
 ip ospf cost 100
!
router ospf
 ospf router-id 3.3.3.3
 network 10.10.0.0/30 area 0.0.0.0
 network 10.20.0.0/30 area 0.0.0.0
!
default-information originate always
!
line vty
!
[root@r3 ~]# systemctl restart zebra ospfd
[root@r3 ~]# ip ro
default via 10.0.2.2 dev eth0 proto dhcp metric 101
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101
10.1.0.0/30 via 10.10.0.1 dev eth2 proto zebra metric 200
10.10.0.0/30 dev eth2 proto kernel scope link src 10.10.0.2 metric 102
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1 metric 100
[root@r3 ~]# tracepath 10.1.0.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.1.0.1                                              1.176ms reached
 1:  10.1.0.1                                              1.159ms reached
     Resume: pmtu 1500 hops 1 back 1
```

