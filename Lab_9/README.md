# Лабораторная работа №9. Управление процессами
 


## Задание: написать свою реализацию `ps -ax`, используя анализ `/proc`

### Краткое описание работы скрипта. 

* Шебанг и указатель на интерпретатор. В переменную добавим каталог 
```
#!/bin/bash
srcDir="/proc/"
```
* Функция конверсии времени в системных тиках в строку вида `mm:ss`.
```
tics_to_ms() {
 ((secs=(${1}/$(getconf CLK_TCK))))
 ((m=$secs/60))
 ((s=$secs%60))
 printf "%d:%02d" $m $s
}
```

* Вывод заголовочных полей таблицы процессов. Инициализация цикла обхода каталога `proc` с выбором только цифровых, отсортированных папок. Переменной `terminal` задаём дефолтное значение.
```
echo -e "PID\tTTY\tSTAT\tTIME\tCOMMAND"
for var in $(ls $srcDir | sort -V | awk '/[[:digit:]]/{print $0}')
do
terminal=" ? "
```

* Проверка на существование файла с наименование процесса: если нет - пропускаем каталог. Проверяем доступен ли первый файловый дескриптор и если да, то отображаем ссылку в качестве консоли с которой стартован процесс.
```
    if [ -f $srcDir$var/comm ]
    then
        if [ -r $srcDir$var/fd/0 ]
        then
            terminal=$(ls -la $srcDir$var/fd | grep dev | head -n 1 |  sed  's/\/dev\//\ /' | awk '{print $11}')
        fi
```

* Из файла `stat` вытаскиваем букву текущего состояния процесса. Также  позиции 14 и 15 означают кол-во времени затраченное на обработку процесса в User и Kernel режимах, параметр **TIME** является суммой этих двух столбцов, дополнительно обработанной для приведения к виду `mm:ss` функцией *tics_to_ms()*
```
        prrocState=$(cat $srcDir$var/stat | awk '{print $3}')
        utime=$(cat $srcDir$var/stat | awk '{print $14}')
        stime=$(cat $srcDir$var/stat | awk '{print $15}')
```

* Проверяем содержимое файла `cmdline` и если оно нулевое, то в качестве параметра **COMMAND** показываем содержимое файла `comm` в квадратных скобках. Иначе меняем в  строке из файла `cmdline` спецсимволы - разделители на традиционные пробелы, чтобы не получить на выходе слитную строку, и полученную строку присваиваем параметру **COMMAND**
```
        if [ "$(cat $srcDir$var/cmdline | wc -c)" -eq 0 ]
        then
            comm="["$(cat $srcDir$var/comm)"]"
        else
            comm=$(cat $srcDir$var/cmdline | tr '\000' ' ')
        fi
```

* Вывод итоговой строки о процессе
```
        echo -e $var"\t"$terminal"\t"$prrocState"\t"$(tics_to_ms $time)"\t"$comm"\t"                                                                
    fi
done
```

* На выводе получаем вариант вывода комманды `ps -ax`
```
[vagrant@psax ~]$ ./psax.sh
PID     TTY     STAT    TIME    COMMAND
1        ?      S       0:08    /usr/lib/systemd/systemd --switched-root --system --deserialize 21
2        ?      S       0:00    [kthreadd]
3        ?      S       0:00    [kworker/0:0]
4        ?      S       0:00    [kworker/0:0H]
5        ?      S       0:00    [kworker/u2:0]
6        ?      S       0:01    [ksoftirqd/0]
7        ?      S       0:00    [migration/0]
8        ?      S       0:00    [rcu_bh]
9        ?      S       0:03    [rcu_sched]
10       ?      S       0:00    [lru-add-drain]
11       ?      S       0:00    [watchdog/0]
13       ?      S       0:00    [kdevtmpfs]
14       ?      S       0:00    [netns]
15       ?      S       0:00    [khungtaskd]
16       ?      S       0:00    [writeback]
17       ?      S       0:00    [kintegrityd]
18       ?      S       0:00    [bioset]
19       ?      S       0:00    [bioset]
20       ?      S       0:00    [bioset]
21       ?      S       0:00    [kblockd]
22       ?      S       0:00    [md]
23       ?      S       0:00    [edac-poller]
24       ?      S       0:00    [watchdogd]
25       ?      S       0:00    [kworker/0:1]
26       ?      S       0:00    [kworker/u2:1]
33       ?      S       0:00    [kswapd0]
34       ?      S       0:00    [ksmd]
35       ?      S       0:00    [crypto]
43       ?      S       0:00    [kthrotld]
44       ?      S       0:00    [kmpath_rdacd]
45       ?      S       0:00    [kaluad]
46       ?      S       0:00    [kpsmoused]
47       ?      S       0:00    [kworker/0:2]
48       ?      S       0:00    [ipv6_addrconf]
61       ?      S       0:00    [deferwq]
95       ?      S       0:00    [kauditd]
133      ?      S       0:00    [ata_sff]
136      ?      S       0:00    [scsi_eh_0]
137      ?      S       0:00    [scsi_tmf_0]
138      ?      S       0:00    [scsi_eh_1]
139      ?      S       0:00    [scsi_tmf_1]
140      ?      S       0:00    [kworker/u2:2]
141      ?      S       0:00    [kworker/u2:3]
155      ?      S       0:00    [bioset]
156      ?      S       0:00    [xfsalloc]
157      ?      S       0:00    [xfs_mru_cache]
158      ?      S       0:00    [xfs-buf/sda1]
159      ?      S       0:00    [xfs-data/sda1]
160      ?      S       0:00    [xfs-conv/sda1]
161      ?      S       0:00    [xfs-cil/sda1]
162      ?      S       0:00    [xfs-reclaim/sda]
163      ?      S       0:00    [xfs-log/sda1]
164      ?      S       0:00    [xfs-eofblocks/s]
165      ?      S       0:00    [xfsaild/sda1]
166      ?      S       0:00    [kworker/0:1H]
228      ?      S       0:00    /usr/lib/systemd/systemd-journald
264      ?      S       0:00    /usr/lib/systemd/systemd-udevd
282      ?      S       0:00    /sbin/auditd
286      ?      S       0:00    [rpciod]
287      ?      S       0:00    [xprtiod]
329      ?      S       0:00    /usr/lib/polkit-1/polkitd --no-debug
334      ?      S       0:00    /usr/lib/systemd/systemd-logind
335      ?      S       0:00    /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation
343      ?      S       0:00    /usr/sbin/chronyd
351      ?      S       0:00    /sbin/rpcbind -w
361      ?      S       0:00    /usr/sbin/gssproxy -D
389      ?      S       0:00    /sbin/agetty --noclear tty1 linux
391      ?      S       0:00    /usr/sbin/crond -n
627      ?      S       0:01    /usr/bin/python2 -Es /usr/sbin/tuned -l -P
631      ?      S       0:00    /usr/sbin/rsyslogd -n
632      ?      S       0:00    /usr/sbin/sshd -D -u0
732      ?      S       0:00    /usr/libexec/postfix/master -w
739      ?      S       0:00    pickup -l -t unix -u
740      ?      S       0:00    qmgr -l -t unix -u
1851     ?      S       0:00    /usr/sbin/NetworkManager --no-daemon
1864     ?      S       0:00    /sbin/dhclient -d -q -sf /usr/libexec/nm-dhcp-helper -pf /var/run/dhclient-eth0.pid -lf /var/lib/NetworkManager/dhclient-5fb06bd0-0bb0-7ffb-45f1-d6edd65f3e03-eth0.lease -cf /var/lib/NetworkManager/dhclient-eth0.conf eth0
2711     ?      S       0:00    sshd: vagrant [priv]
2714     ?      S       0:00    sshd: vagrant@pts/0
2715    pts/0   S       0:00    -bash
2739    pts/0   S       0:00    /bin/bash ./psax.sh
```

## Результат работы
* В репозиторий **GitHUB** добавлен [psax.sh](https://github.com/OlegLitvintsev/OTUS_Lab/blob/master/Lab_9/psax.sh), который выводит требуемые данные и [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Lab/blob/master/Lab_9/Vagrantfile), поднимающий тестовую VM и копирующий скрипт [psax.sh](https://github.com/OlegLitvintsev/OTUS_Lab/blob/master/Lab_9/psax.sh) внутрь VM в каталог `/home/vagrant`.
