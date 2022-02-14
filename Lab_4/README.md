# Лабораторная работа №4.  Практические навыки работы с ZFS.

## Настройка окружения

* Использовался образ **centos/7** версии 2004.01

## Порядок работы

### 1. Определить алгоритм с наилучшим сжатием
* создаем 4 файловых системы, на каждой применяем свой алгоритм сжатия
```
[root@zfs ~]# zpool create otus1 mirror /dev/sdb /dev/sdc
[root@zfs ~]# zpool create otus2 mirror /dev/sdd /dev/sde
[root@zfs ~]# zpool create otus3 mirror /dev/sdf /dev/sdg
[root@zfs ~]# zpool create otus4 mirror /dev/sdh /dev/sdi
[root@zfs ~]# zfs set compression=lzjb otus1
[root@zfs ~]# zfs set compression=lz4 otus2
[root@zfs ~]# zfs set compression=gzip-9 otus3
[root@zfs ~]# zfs set compression=zle otus4                                                         
```
* скачиваем файл https://gutenberg.org/cache/epub/2600/pg2600.converter.log на все 4 ранее созданные файловые системы
```
[root@zfs ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```
* результат - вывод команды **zfs get all | grep compressratio | grep -v ref**, из которого видно, какой из алгоритмов сжатия эффективнее
```
[root@zfs ~]# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.81x                  -
otus2  compressratio         2.22x                  -
otus3  compressratio         3.64x                  -
otus4  compressratio         1.00x                  -
```
* вывод: алгоритм сжатия **gzip-9** эффективнее
  
### 2. Определение настроек пула
* скачиваем архив в домашний каталог
```
[root@zfs ~]# wget -O archive.tar.gz --no-check-certificate https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download
```
* разархивируем его
```
[root@zfs ~]# tar -xzvf archive.tar.gz
```
* проверим, возможно ли импортировать данный каталог в пул
```
[root@zfs ~]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE
```
* импорт возможен, импортируем пул
```
[root@zfs ~]# zpool import -d zpoolexport/ otus
```
* импорт прошел успешно
```
[root@zfs ~]# zpool status otus
  pool: otus
 state: ONLINE
  scan: none requested
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```
* определение настроек импортированного пула
```
[root@zfs ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
[root@zfs ~]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
[root@zfs ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
[root@zfs ~]# zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local
[root@zfs ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```
### 3. Работа со снапшотом, поиск сообщения от преподавателя
* скачиваем файл снапшота https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
```
[root@zfs ~]# wget -O otus_task2.file --no-check-certificate https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
```
* импортируем снапшот
```
[root@zfs ~]# zfs receive otus/test@today < otus_task2.file
```
* ищем файл с секретной фразой (с неприметным именем **secret_message**)
```
[root@zfs ~] find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
```
* нашли, смотрим, а вот и фраза
```
[root@zfs ~]# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
```


## Результат работы

* В репозиторий GitHUB добавлен [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_4/Vagrantfile), а так же скрипт [ZFS_install.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_4/ZFS_install.sh) установки ZFS в виртуальную машину при ее создании, на который есть ссылка в [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_4/Vagrantfile)
* В репозиторий GitHUB добавлен лог [typescript](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_4/typescript) процесса выполнения лабораторной работы, сформированный утилитой SCRIPT
* В репозиторий GitHUB добавлено описание [README.md](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_4/README.md)
