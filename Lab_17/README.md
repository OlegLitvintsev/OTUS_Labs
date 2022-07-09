# Лабораторная работа №16. Настройка централизованного сервера для сбора логов

## Задание: настроить централизованный сервер для сбора логов

* в вагранте поднимаем 2 машины web (**log-client**) и log (**log-server**)
* на web поднимаем **NGINX**
* на log настраиваем центральный лог сервер посредством **Rsyslog**
* настраиваем аудит следящий за изменением конфигов **NGINX**

* все критичные логи с web должны собираться и локально и удаленно
* все логи с **NGINX** должны уходить на удаленный сервер (локально только критичные)
* логи аудита должны также уходить на удаленную систему

## Решение

* В репозиторий **GitHUB** добавлен [Vagrant файл](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_17/Vagrantfile),  который  разворачивает требуемый стенд из 2 виртуалок посредством шелл скриптов 
для web (log-client)  ([client.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_17/client.sh)) и для и log (log-server) ([server.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_17/server.sh))

### Описание действий для автонастройки сервера логов 

#### В провижне стартует внешний скрипт **server.sh**, выполняющий следующие действия:

Производится установка **Rsyslog** и **policycoreutils-python** для открытия портов в **SELinux**

```
yum install -y rsyslog policycoreutils-python 
```

Производится открытие 514 порта для протоколов **tcp** и **udp** в **SELinux** для приёма логов **Rsyslog** 

```
semanage port -m -t syslogd_port_t -p tcp 514
semanage port -m -t syslogd_port_t -p udp 514
```

Конфигурирование конфига **Rsyslog** 
* в 1 строке указываются  порты для прослушивания 
* во 2 строке добавляются шаблоны для обработке входящих событий - распределение по папкам с наименованием как у машины-источника и в соответствующий сервису файл. Также создаётся отдельный шаблон для обработки событий аудита (```facility = local6```)
* выполняется старт и добавление в автозапуск службы **Rsyslog** 

```
sed -i 's/#$ModLoad imtcp/$ModLoad imtcp/; s/#$InputTCPServerRun 514/$InputTCPServerRun 514/; s/#$ModLoad imudp/$ModLoad imudp/; s/#$UDPServerRun 514/$UDPServerRun 514/' /etc/rsyslog.conf
echo -e "\n\$template HostAudit, \"/var/log/rsyslog/%HOSTNAME%/audit.log\"\nlocal6.* ?HostAudit\n\$template RemoteLogs,\"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log\"\n*.* ?RemoteLogs\n& ~\n" >> /etc/rsyslog.conf
systemctl start rsyslog && systemctl enable rsyslog
```

#### Далее в провижне стартует inline shell скрипт, который добавляет  в политики безопасности  **SELinux** изменения, разрешающие службе **Rsyslog** доступ к журналу аудита 

```
semodule -i /home/vagrant/my-rsyslogd.pp
semodule -i /home/vagrant/my-inimfile.pp
systemctl restart rsyslog 
```

*Файлы политики были сгенерены заранее, но можно было также добавить их генерацию во внешний скрипт, что потребовало бы иммитации активности для появления событий и регистрации ошибок доступа для для последующей генерации политик посредством команд:*

```
sealert -a /var/log/audit/audit.log
ausearch -c 'rsyslogd' --raw | audit2allow -M my-rsyslogd
ausearch -c 'in:imfile' --raw | audit2allow -M my-inimfile
semodule -i my-rsyslogd.pp
semodule -i my-inimfile.pp
```	

### Описание действий для автонастройки клиентской машины логов **log-client** (машины web)

#### В провижне стартует внешний скрипт **client.sh**, выполняющий следующие действия:

Производится установка **Rsyslog** и веб сервера **NGINX** совместно с необходимым репозиторием **epel-release**

```
yum install epel-release -y && yum install -y nginx rsyslog 
```

Производится изменение конфига **NGINX** для настройки удалённого и локального сбора событий, согласно заданию. Далее старт и добавление в автозапуск службы **NGINX**

```
sed -i 's#error_log /var/log/nginx/error.log;#error_log /var/log/nginx/error.log warn;\nerror_log syslog:server=192.168.50.10;#; s#access_log  /var/log/nginx/access.log  main;#access_log  syslog:server=192.168.50.10 combined;#' /etc/nginx/nginx.conf
systemctl start nginx && systemctl enable nginx 
```	

Воплняется добавление в аудит событий слежки за каталогом с конфигаруциями **NGINX** **/etc/nginx/** и рестарт службы **auditd**

```	
echo "-w /etc/nginx/ -p wa -k NGNX_conf" > /etc/audit/rules.d/ngnx.rules && service auditd restart
```	

Настройка отправки критичных событий на централизованный сервер **Rsyslog** 

```
echo -e "*.crit @@192.168.50.10:514\n*.err @@192.168.50.10:514\n" > /etc/rsyslog.d/crit.conf 
```

Настройка отправки событий из журнала аудита  на централизованный сервер. Старт и добавление в автозапуск службы **Rsyslog**.
 
```
echo -e "\$ModLoad imfile\n\$InputFileName /var/log/audit/audit.log\n\$InputFileTag tag_audit_log:\n\$InputFileStateFile audit_log\n\$InputFileSeverity info\n\$InputFileFacility local6\n\$InputRunFileMonitor\n\n*.*   @@192.168.50.10:514\n" > /etc/rsyslog.d/audit.conf 
systemctl enable rsyslog && systemctl start rsyslog
```

#### Далее в провижне аналогично серверу стартует inline shell скрипт, который добавляет  в политики безопасности  **SELinux** изменения, разрешающие службе **Rsyslog** доступ к журналу аудита 

```
semodule -i /home/vagrant/my-rsyslogd.pp
semodule -i /home/vagrant/my-inimfile.pp
systemctl restart rsyslog 
```

## Проверка работы стенда

* На сервере сбора логов имеется каталог журналов событий с клиентской машины. Производится обращение к несуществующей странице веб сервера **NGINX** на клиентской машине - в соответствующем журнале появляются записи об ошибке.
```
[vagrant@log-server ~]$ curl 192.168.50.11/dhfjsfskdjfasklfjl | grep title
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3650  100  3650    0     0   197k      0 --:--:-- --:--:-- --:--:--  237k
        <title>The page is not found</title>
[vagrant@log-server ~]$ sudo cat /var/log/rsyslog/log-client/nginx.log
Jul  9 04:00:06 log-client nginx: 2022/07/09 04:00:06 [error] 3799#3799: *2 open() "/usr/share/nginx/html/dhfjsfskdjfasklfjl" failed (2: No such file or directory), client: 192.168.50.10, server: _, request: "GET /dhfjsfskdjfasklfjl HTTP/1.1", host: "192.168.50.11"
Jul  9 04:00:06 log-client nginx: 192.168.50.10 - - [09/Jul/2022:04:00:06 +0000] "GET /dhfjsfskdjfasklfjl HTTP/1.1" 404 3650 "-" "curl/7.29.0"
```

* На клиенте выполняется изменение внутри отслеживаемого каталога конфигураций **NGINX**
```
[vagrant@log-client ~]$ sudo su
[root@log-client vagrant]# touch /etc/nginx/conf.d/test.conf && ls -la /etc/nginx/conf.d/ && rm -f /etc/nginx/conf.d/test.conf
total 4
drwxr-xr-x. 2 root root   23 Jul  9 04:09 .
drwxr-xr-x. 4 root root 4096 Jul  9 03:55 ..
-rw-r--r--. 1 root root    0 Jul  9 04:09 test.conf
```

* На сервере в соответствующем журнале появляются записи
```
[vagrant@log-server ~]$ sudo cat /var/log/rsyslog/log-client/audit.log | grep test.conf
Jul  9 04:09:18 log-client tag_audit_log: type=PATH msg=audit(1657339750.660:1276): item=1 name="/etc/nginx/conf.d/test.conf" inode=12540 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:httpd_config_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
Jul  9 04:09:18 log-client tag_audit_log: type=PATH msg=audit(1657339765.847:1277): item=1 name="/etc/nginx/conf.d/test.conf" inode=12540 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:httpd_config_t:s0 objtype=DELETE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
```

