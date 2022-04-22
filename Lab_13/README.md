# Лабораторная работа №13.  Systemd

## Задачи

1. Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig);
2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя сервиса должно называться так же: spawn-fcgi);
3. Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.


## Решение 
* В репозиторий **GitHUB** добавлен [Vagrant файл](https://github.com/OlegLitvintsev/OTUS_Labs/blob/main/Lab_13/Vagrantfile)
```
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
    :systemd => {
        :box_name => "centos/7",
        :box_version => "2004.01",
    },
}

Vagrant.configure("2") do |config|
    MACHINES.each do |boxname, boxconfig|
        config.vm.define boxname do |box|
            box.vm.box = boxconfig[:box_name]
            box.vm.box_version = boxconfig[:box_version]

            box.vm.host_name = "systemd"
            box.vm.network "forwarded_port", guest: 80, host: 80
            box.vm.network "forwarded_port", guest: 8080, host: 8080

            box.vm.provider :virtualbox do |vb|
                vb.customize ["modifyvm", :id, "--memory", "1024"]
                needsController = false
            end

            box.vm.provision "shell", path: "systemd.sh"
        end
    end
end
```

который стартует скрипт, выполняющий все задания ([systemd.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_13/systemd.sh)) 

```
#!/bin/bash
echo "Provision script"
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
#TASK 1
echo -e "WORD=\"ALERT\"\nLOG=\"/var/log/watchlog.log\"" > /etc/sysconfig/watchlog
printf '%s\n' '#!/bin/bash' 'WORD=$1' 'LOG=$2' 'DATE=`date`' 'if grep $WORD $LOG &> /dev/null' 'then' 'logger "$DATE: I found word, Master!"' 'else' 'exit 0' 'fi' > /opt/watchlog.sh  && chmod +x /opt/watchlog.sh
echo -e "[Unit]\nDescription=My watchlog service\n[Service]\nType=oneshot\nEnvironmentFile=/etc/sysconfig/watchlog\nExecStart=/opt/watchlog.sh \$WORD \$LOG\n" > /etc/systemd/system/watchlog.service
echo -e "[Unit]\nDescription=Run watchlog script every 30 second\n[Timer]\nOnBootSec=1m\nOnUnitActiveSec=30\nUnit=watchlog.service\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/watchlog.timer
echo -e "[$(date +%d-%m-%Y%t%H:%M:%S)]: [INFO] New session created\n[$(date +%d-%m-%Y%t%H:%M:%S)]: [ALERT] It's looks like a intruder's attack.\n[$(date +%d-%m-%Y%t%H:%M:%S)]: [INFO] I'll kill this session now.\n[$(date +%d-%m-%Y%t%H:%M:%S)]: [ERROR] Sorry, I can't  kill this session." > /var/log/watchlog.log
#TASK 2
echo -e "[Unit]\nDescription=Spawn-fcgi startup service by Otus\nAfter=network.target\n[Service]\nType=simple\nPIDFile=/var/run/spawn-fcgi.pid\nEnvironmentFile=/etc/sysconfig/spawn-fcgi\nExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS\nKillMode=process\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/spawn-fcgi.service
sed -i 's/#SOCKET/SOCKET/; s/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi
#TASK 3
cp /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/httpd@.service
sed -i 's/sysconfig\/httpd/sysconfig\/httpd-%I/' /usr/lib/systemd/system/httpd@.service
cp  /etc/sysconfig/httpd /etc/sysconfig/httpd-first && cp  /etc/sysconfig/httpd /etc/sysconfig/httpd-second
sed -i 's/#OPTIONS=/OPTIONS=-f conf\/first.conf/' /etc/sysconfig/httpd-first
sed -i 's/#OPTIONS=/OPTIONS=-f conf\/second.conf/' /etc/sysconfig/httpd-second
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf &&  cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
sed -i 's/Listen 80/Listen 80\nPidFile \/var\/run\/httpd-first.pid/' /etc/httpd/conf/first.conf
sed -i 's/Listen 80/Listen 8080\nPidFile \/var\/run\/httpd-second.pid/' /etc/httpd/conf/second.conf
systemctl daemon-reload
#TASK 1 service
systemctl enable watchlog.service
systemctl enable watchlog.timer
systemctl start watchlog.timer
#TASK 2 service
systemctl enable spawn-fcgi
systemctl start spawn-fcgi
#TASK 3 service
systemctl start httpd@first
systemctl start httpd@second
```


* После загрузки образа и отработки скрипта сделана проверка
```
[vagrant@systemd ~]$ sudo -i
[root@systemd ~]# tail -f /var/log/messages
Apr 22 13:57:34 localhost systemd: Started My watchlog service.
Apr 22 13:58:03 localhost systemd: Created slice User Slice of vagrant.
Apr 22 13:58:03 localhost systemd: Started Session 4 of user vagrant.
Apr 22 13:58:03 localhost systemd-logind: New session 4 of user vagrant.
Apr 22 13:58:04 localhost systemd: Starting My watchlog service...
Apr 22 13:58:04 localhost root: Fri Apr 22 13:58:04 UTC 2022: I found word, Master!
Apr 22 13:58:04 localhost systemd: Started My watchlog service.
Apr 22 13:58:34 localhost systemd: Starting My watchlog service...
Apr 22 13:58:34 localhost root: Fri Apr 22 13:58:34 UTC 2022: I found word, Master!
Apr 22 13:58:34 localhost systemd: Started My watchlog service.
Apr 22 13:59:04 localhost systemd: Starting My watchlog service...
Apr 22 13:59:04 localhost root: Fri Apr 22 13:59:04 UTC 2022: I found word, Master!
Apr 22 13:59:04 localhost systemd: Started My watchlog service.
^C
[root@systemd ~]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2022-04-22 13:56:35 UTC; 3min 14s ago
 Main PID: 2924 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─2924 /usr/bin/php-cgi
           ├─2927 /usr/bin/php-cgi
           ├─2928 /usr/bin/php-cgi
           ├─2929 /usr/bin/php-cgi
           ├─2930 /usr/bin/php-cgi
           ├─2931 /usr/bin/php-cgi
           ├─2932 /usr/bin/php-cgi
           ├─2933 /usr/bin/php-cgi
           ├─2934 /usr/bin/php-cgi
           ├─2935 /usr/bin/php-cgi
           ├─2936 /usr/bin/php-cgi
           ├─2937 /usr/bin/php-cgi
           ├─2938 /usr/bin/php-cgi
           ├─2939 /usr/bin/php-cgi
           ├─2940 /usr/bin/php-cgi
           ├─2941 /usr/bin/php-cgi
           ├─2942 /usr/bin/php-cgi
           ├─2943 /usr/bin/php-cgi
           ├─2944 /usr/bin/php-cgi
           ├─2945 /usr/bin/php-cgi
           ├─2946 /usr/bin/php-cgi
           ├─2947 /usr/bin/php-cgi
           ├─2948 /usr/bin/php-cgi
           ├─2949 /usr/bin/php-cgi
           ├─2950 /usr/bin/php-cgi
           ├─2951 /usr/bin/php-cgi
           ├─2952 /usr/bin/php-cgi
           ├─2953 /usr/bin/php-cgi
           ├─2954 /usr/bin/php-cgi
           ├─2955 /usr/bin/php-cgi
           ├─2956 /usr/bin/php-cgi
           ├─2957 /usr/bin/php-cgi
           └─2958 /usr/bin/php-cgi

Apr 22 13:56:35 systemd systemd[1]: Started Spawn-fcgi startup service by Otus.
[root@systemd ~]# ss -tnulp | grep httpd
tcp    LISTEN     0      128    [::]:8080               [::]:*                   users:(("httpd",pid=2972,fd=4),("httpd",pid=2971,fd=4),("httpd",pid=2970,fd=4),("httpd",pid=2969,fd=4),("httpd",pid=2968,fd=4),("httpd",pid=2967,fd=4),("httpd",pid=2966,fd=4))
tcp    LISTEN     0      128    [::]:80                 [::]:*                   users:(("httpd",pid=2964,fd=4),("httpd",pid=2963,fd=4),("httpd",pid=2962,fd=4),("httpd",pid=2961,fd=4),("httpd",pid=2960,fd=4),("httpd",pid=2959,fd=4),("httpd",pid=2926,fd=4))
```
