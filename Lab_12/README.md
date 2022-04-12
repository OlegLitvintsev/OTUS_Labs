# Лабораторная работа №12. SELinux

## Задача 1. Запуск nginx на нестандартном порту

* Запустить nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.

### Решение 

* Разворачивается хост с образа **centos/7**, устанавливается **nginx**, устанавливается **policycoreutils-python** и **setroubleshoot** для анализа журналов аудита. По умолчанию **SELinux** работает в статусе **Enforcing**. В конфигурационном файле **nginx** устанавливается порт **4881** и выполняется попытка старта приложения, которая оканчивается ошибкой, причина  - невозможность привязки к порту **4881**
```
selinux: Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
    selinux: ● nginx.service - The nginx HTTP and reverse proxy server
    selinux:    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
    selinux:    Active: failed (Result: exit-code) since Tue 2022-04-12 11:59:30 UTC; 37ms ago
    selinux:   Process: 2839 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
    selinux:   Process: 2838 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    selinux:
    selinux: Apr 12 11:59:30 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
    selinux: Apr 12 11:59:30 selinux nginx[2839]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    selinux: Apr 12 11:59:30 selinux nginx[2839]: nginx: [emerg] bind() to [::]:4881 failed (13: Permission denied)
    selinux: Apr 12 11:59:30 selinux nginx[2839]: nginx: configuration file /etc/nginx/nginx.conf test failed
    selinux: Apr 12 11:59:30 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
    selinux: Apr 12 11:59:30 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
    selinux: Apr 12 11:59:30 selinux systemd[1]: Unit nginx.service entered failed state.
    selinux: Apr 12 11:59:30 selinux systemd[1]: nginx.service failed.
```
* Заходим на хост и удостоверяемся, что нам не мешает файрволл
```
den@fwst:~/OTUS_Labs/Lab_12$ vagrant ssh
[vagrant@selinux ~]$ sudo -i
[root@selinux ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
```
* Выполняем проверку журнала аудита
```
[root@selinux ~]# cat /var/log/audit/audit.log | grep 4881
type=AVC msg=audit(1649764770.163:826): avc:  denied  { name_bind } for  pid=2839 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
[root@selinux ~]# grep 1649764770.163:826 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1649764770.163:826): avc:  denied  { name_bind } for  pid=2839 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```
  * включим параметр **nis_enabled**, в результате **nginx** успешно стартовал
```
[root@selinux ~]# setsebool -P nis_enabled on
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2022-04-12 12:52:16 UTC; 12s ago
  Process: 23480 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 23478 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 23476 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 23482 (nginx)
   CGroup: /system.slice/nginx.service
           ├─23482 nginx: master process /usr/sbin/nginx
           └─23483 nginx: worker process

Apr 12 12:52:15 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 12 12:52:16 selinux nginx[23478]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 12 12:52:16 selinux nginx[23478]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Apr 12 12:52:16 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

* Вернём запрет работы **nginx** на порту **4881** обратно. Для этого отключим **nis_enabled**. После отключения **nis_enabled** служба **nginx** снова не запускается.
```
[root@selinux ~]# setsebool -P nis_enabled off
[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Tue 2022-04-12 13:01:09 UTC; 11s ago
  Process: 23480 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 23514 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 23513 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 23482 (code=exited, status=0/SUCCESS)

Apr 12 13:01:09 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Apr 12 13:01:09 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 12 13:01:09 selinux nginx[23514]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 12 13:01:09 selinux nginx[23514]: nginx: [emerg] bind() to [::]:4881 failed (13: Permission denied)
Apr 12 13:01:09 selinux nginx[23514]: nginx: configuration file /etc/nginx/nginx.conf test failed
Apr 12 13:01:09 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
Apr 12 13:01:09 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Apr 12 13:01:09 selinux systemd[1]: Unit nginx.service entered failed state.
Apr 12 13:01:09 selinux systemd[1]: nginx.service failed.
```

* Теперь разрешим в SELinux работу nginx на порту TCP **4881** c помощью добавления нестандартного порта в имеющийся тип, в результате **nginx** успешно стартовал
```
[root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2022-04-12 13:09:13 UTC; 5s ago
  Process: 23565 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 23563 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 23561 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 23568 (nginx)
   CGroup: /system.slice/nginx.service
           ├─23568 nginx: master process /usr/sbin/nginx
           └─23569 nginx: worker process

Apr 12 13:09:12 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 12 13:09:13 selinux nginx[23563]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 12 13:09:13 selinux nginx[23563]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Apr 12 13:09:13 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

* Снова в конфигурации **nginx** меняется порт и производится неудачная попытка его рестарта
```
[root@selinux ~]# semanage port -d -t http_port_t -p tcp 4881
[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Tue 2022-04-12 13:13:11 UTC; 3s ago
  Process: 23565 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 23586 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 23585 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 23568 (code=exited, status=0/SUCCESS)

Apr 12 13:13:11 selinux systemd[1]: Stopped The nginx HTTP and reverse proxy server.
Apr 12 13:13:11 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 12 13:13:11 selinux nginx[23586]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 12 13:13:11 selinux nginx[23586]: nginx: [emerg] bind() to [::]:4881 failed (13: Permission denied)
Apr 12 13:13:11 selinux nginx[23586]: nginx: configuration file /etc/nginx/nginx.conf test failed
Apr 12 13:13:11 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
Apr 12 13:13:11 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Apr 12 13:13:11 selinux systemd[1]: Unit nginx.service entered failed state.
Apr 12 13:13:11 selinux systemd[1]: nginx.service failed.
```
* Разрешим в SELinux работу **nginx** на порту TCP **4881** c помощью формирования и установки модуля SELinux, в результате **nginx** успешно стартовал
```
[root@selinux ~]# ausearch -c 'nginx' --raw | audit2allow -M my-nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i my-nginx.pp

[root@selinux ~]# semodule -i my-nginx.pp
[root@selinux ~]# systemctl restart nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2022-04-12 13:18:33 UTC; 3s ago
  Process: 23627 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 23625 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 23623 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 23629 (nginx)
   CGroup: /system.slice/nginx.service
           ├─23629 nginx: master process /usr/sbin/nginx
           └─23630 nginx: worker process

Apr 12 13:18:32 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Apr 12 13:18:33 selinux nginx[23625]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Apr 12 13:18:33 selinux nginx[23625]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Apr 12 13:18:33 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
``` 

## Задача 2. Устранение проблемы с удаленным обновлением зоны DNS

- Развернуть [стенд](https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems)
- Выяснить причину неработоспособности механизма обновления зоны;
- Предложить решение (или решения) для данной проблемы;
- Выбрать одно из решений для реализации, предварительно обосновав выбор;
- Реализовать выбранное решение и продемонстрировать его работоспособность.

### Решение 

* Разворачиваеется система из 2 хостов, на которых посредством **Ansible** выполняется установка и настройка **dns** (сервер и клиент). Далее с клиентского хоста выполняется попытка обновления зоны, которая заканчивается неудачно.
```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
```
* Проверяем доступность сервера - сервер доступен
```
[vagrant@client ~]$ dig @192.168.50.10 ns01.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.9 <<>> @192.168.50.10 ns01.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13920
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;ns01.dns.lab.                  IN      A

;; ANSWER SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns01.dns.lab.

;; Query time: 7 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Apr 12 14:46:04 UTC 2022
;; MSG SIZE  rcvd: 71
```
* Cмотрим логи SELinux на клиенте - блокировок нет
```
[root@client ~]# cat /var/log/audit/audit.log | audit2why
```
* Cмотрим логи SELinux на сервере - ошибка в контексте безопасности. Вместо контекста **named_t** используется контекст **etc_t**
```
[root@ns01 ~]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1649772096.911:1924): avc:  denied  { create } for  pid=5115 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Unknown - would be allowed by active policy
                Possible mismatch between this policy and the one under which the audit message was generated.

                Possible mismatch between current in-memory boolean settings vs. permanent ones.

type=AVC msg=audit(1649772728.755:1952): avc:  denied  { write } for  pid=5115 comm="isc-worker0000" path="/etc/named/dynamic/named.ddns.lab.view1.jnl" dev="sda1" ino=5244066 scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```
* Проверим данную проблему в каталоге **/etc/named** - контекст безопасности неправильный. Проблема заключается в том, что файлы данных **named** расположены в **/etc/named/**, а должны, согласно политике SELinux, в **/var/named/**
```
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
[root@ns01 ~]# sudo semanage fcontext -l | grep named
/etc/rndc.*                                        regular file       system_u:object_r:named_conf_t:s0
/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0
```
* Изменим тип контекста безопасности для каталога /etc/named
```
[root@ns01 ~]# sudo chcon -R -t named_zone_t /etc/named
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab
```
* Пробуем снова внести изменения с клиента - изменения применились
```
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
[root@client ~]# dig www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.9 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 6648
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.               3600    IN      NS      ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10

;; Query time: 7 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Apr 12 14:50:22 UTC 2022
;; MSG SIZE  rcvd: 96
```
* более правильным было бы решение, основанное на исправлении пути расположения файлов данных **named** в плейбуке исходного [стенда](https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems) с **/etc/named** на **/var/named/**, в таком случае стенд работал бы сразу, без необходимости реконфигурации политик SELinux на сервере DNS

