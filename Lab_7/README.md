# Лабораторная работа № 7. BASH

## Задание: написать скрипт для крона, который раз в час присылает на заданную почту:

* X IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта
* Y запрашиваемых адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта
* все ошибки c момента последнего запуска
* список всех кодов возврата с указанием их кол-ва с момента последнего запуска
* должна быть реализована защита от мультизапуска скрипта
* в письме должен быть прописан обрабатываемый временной диапазон


## Решение

* В репозиторий **GitHUB** добавлен [Vagrant файл](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/Vagrantfile),  который  разворачивает виртуальную машину и копирует в нее скрипт анализа лога **NGINX** ([anlog.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/anlog.sh)) и фрагмент лога **NGINX** ([access-4560-644067.log](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/access-4560-644067.log)), и при помощи скрипта [crn.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/crn.sh) заносит скрипт [anlog.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/anlog.sh) в **crontab** пользователя **vagrant**. Содержимое скрипта [anlog.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/anlog.sh) приведено ниже
```
#!/bin/bash

# variables
LOGFILE="/home/vagrant/access-4560-644067.log"
TEMPFILE="/home/vagrant/temp.log"
REPORT="/home/vagrant/report.txt"
IPs="10"
URLs="10"
SUCCESS_RESPONSE_CODE="200"
IFS=$'\n'
SEND_TO="webadmin@otus.ru"

# functions
filter_errors(){
grep -v $SUCCESS_RESPONSE_CODE
}


request_ips(){
awk '{print $1}'
}


request_return_codes(){
awk '{print $9}'
}

request_pages(){
awk '{print $7}'
}

wordcount(){
sort \
| uniq -c
}

sort_desc(){
sort -rn
}

return_kv(){
awk '{print $1, $2}'
}

return_error_requests(){
awk '{print $7}'
}


request_pages(){
awk '{print $7}'
}

return_top_IPs(){
head -$IPs
}

return_top_URLs(){
head -$URLs
}

# actions
get_request_ips(){
echo ""
echo "Top $IPs requesters IP's:"
echo "========================="

cat $TEMPFILE \
| request_ips \
| wordcount \
| sort_desc \
| return_kv \
| return_top_IPs
echo ""
}

get_request_pages(){
echo "Top $URLs requested pages:"
echo "=========================="
cat $TEMPFILE \
| request_pages \
| wordcount \
| sort_desc \
| return_kv \
| return_top_URLs
echo ""
}

get_request_errors(){
echo "Error requests:"
echo "==============="
cat $TEMPFILE \
| filter_errors \
| return_error_requests \
| wordcount \
| sort_desc
echo ""
}

get_return_codes(){
echo "Return codes:"
echo "============="
cat $TEMPFILE \
| request_return_codes \
| wordcount \
| sort_desc
echo ""
}

# executing

if [[ "$(ps -ef | grep anlog.sh | grep -v grep | wc -l)" -gt 2 ]]
  then
        echo "Script already running"
        exit 1
fi

if  [ ! -f $TEMPFILE ]
then
    tflg=0
else
    tflg=$(date -r $TEMPFILE +%s)
    rm -f $TEMPFILE
fi

for var in $(cat $LOGFILE)
do
   if [[ "$(date -d "$(echo $var | awk '{print $4}' | sed 's/\[//;s/:/ /;s/\// /;s/\// /')" +%s)" -gt "($tflg + 3600)" ]]
      then
        echo $var >> $TEMPFILE
   fi
done

if  [ -f $REPORT ]
then

    rm -f $REPORT
fi


echo "=================== This report is based on the log events for the interval " >> $REPORT
date -d@$tflg >> $REPORT
date  -r $TEMPFILE >> $REPORT

get_request_ips >> $REPORT
get_request_pages >> $REPORT
get_request_errors >> $REPORT
get_return_codes >> $REPORT

# mail -s 'NGINX logs report' -a $REPORT $SEND_TO

```

## Описание скрипта [anlog.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/anlog.sh)

* переменная LOGFILE задает расположение файла анализируемого лога
* переменная TEMPFILE задает расположение временного файла - часовой выборки со времени последнего анализа из файла анализируемого лога, заодно время последней его модификации является временной меткой начала выборки при следующем запуске скрипта
* переменная REPORT задает расположение файла генерируемого отчета
* переменная IPs задает количество выводимых в отчет IP адресов с наибольшим количеством запросов
* переменная URLs задает количество выводимых в отчет наиболее запрашиваемых адресов
* переменная SEND_TO задает почтовый адрес для отсылки отчета

## Проверка работы скрипта [anlog.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/anlog.sh)

* после старта виртуальной машины проверяем наличие записи в **crontab**
```
[vagrant@anlog ~]$ crontab -l

0 * * * * /home/vagrant/anlog.sh
```

* после первого запуска скрипта [anlog.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/anlog.sh) в каталоге **/home/vagrant** появляется файл **report.txt** следующего содержимого 
```
=================== This report is based on the log events for the interval
Thu Jan  1 00:00:00 UTC 1970
Wed Jul 13 14:23:47 UTC 2022

Top 10 requesters IP's:
=========================
45 93.158.167.130
39 109.236.252.130
37 212.57.117.19
33 188.43.241.106
31 87.250.233.68
24 62.75.198.172
22 148.251.223.21
20 185.6.8.9
17 217.118.66.161
16 95.165.18.146

Top 10 requested pages:
==========================
157 /
120 /wp-login.php
57 /xmlrpc.php
26 /robots.txt
12 /favicon.ico
11 400
9 /wp-includes/js/wp-embed.min.js?ver=5.0.4
7 /wp-admin/admin-post.php?page=301bulkoptions
7 /1
6 /wp-content/uploads/2016/10/robo5.jpg

Error requests:
===============
     83 /
     11 400
      7 /robots.txt
      7 /1
      6 /wp-admin/admin-ajax.php?page=301bulkoptions
      4 /wp-login.php
      3 /wp-content/uploads/2016/10/robo5.jpg
      3 /wp-content/uploads/2016/10/robo4.jpg
      3 /wp-content/uploads/2016/10/robo3.jpg
      3 /wp-content/uploads/2016/10/robo2.jpg
      3 /wp-content/uploads/2016/10/robo1.jpg
      3 /wp-content/uploads/2016/10/aoc-1.jpg
      3 /wp-content/uploads/2016/10/agreed.jpg
      3 /wp-admin/admin-post.php?page=301bulkoptions
      2 /wp-content/uploads/2016/10/dc.jpg
      2 /wp-content/plugins/uploadify/includes/check.php
      2 /sitemap.xml
      2 /admin/config.php
      2 /.well-known/security.txt
      2 /%D0%A3%D0%B4%D0%B0%D0%BB%D0%B5%D0%BD%D0%BD%D0%BE%D0%B5-%D0%B0%D0%B4%D0%BC%D0%B8%D0%BD%D0%B8%D1%81%D1%82%D1%80%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D0%A1%D0%A3%D0%91%D0%94-oracle/
      1 http://110.249.212.46/testget?q=23333&port=80
      1 http://110.249.212.46/testget?q=23333&port=443
      1 /wp-includes/ID3/comay.php
      1 /wp-cron.php?doing_wp_cron=1565803543.6812090873718261718750
      1 /wp-cron.php?doing_wp_cron=1565760219.4257180690765380859375
      1 /wp-content/uploads/2018/08/seo_script.php
      1 /wp-content/themes/llorix-one-lite/fonts/fontawesome-webfont.eot?
      1 /wp-content/plugins/uploadify/readme.txt
      1 /webdav/
      1 /w00tw00t.at.ISC.SANS.DFind:)
      1 /tag/dublicate/
      1 /manager/html
      1 /feed/
      1 /favicon.ico
      1 /admin//config.php
      1 /?xxxxxxxxxxxx_loads=1&xxxxxxxxxxxx_filename=info.txt&xxxxxxxxxxxx_filecontent=INF0
      1 //wp-content/plugins/license.php

Return codes:
=============
    498 200
     95 301
     51 404
     11 "-"
      7 400
      3 500
      2 499
      1 405
      1 403
      1 304

```
* при втором и последующих запусках скрипта [anlog.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_7/anlog.sh) в каталоге **/home/vagrant** появляется файл **report.txt** следующего содержимого
```
=================== This report is based on the log events for the interval
Wed Jul 13 14:23:47 UTC 2022
Wed Jul 13 14:26:15 UTC 2022

Top 10 requesters IP's:
=========================
1 200.33.155.30

Top 10 requested pages:
==========================
1 /

Error requests:
===============

Return codes:
=============
      1 200

```

* содержимое файла **report.txt** при первом запуске скрипта обусловлено тем, что отсутствие в каталоге временного файла предыдущей обработки приводит к обработке всего лога, начиная с Thu Jan  1 00:00:00 UTC 1970
* содержимое файла **report.txt** при втором и последующих запусков скрипта обусловлено тем, что дата первой записи лога намеренно исправлена на 14/Aug/2025, иначе второй и последующие отчеты были бы пустыми ввиду статичности лога (в него никто не пишет в настоящее время)
* ошибкой считается любой запрос, закончившийся ответом сервера, отличным от кода 200
* строка отправки отчета по почте закомментирована ввиду того, что полная конфигурация работающего почтового окружения по понятным причинам не приводится
