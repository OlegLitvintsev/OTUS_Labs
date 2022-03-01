# Лабораторная работа №6.  Размещаем свой RPM в своем репозитории
 
## Настройка окружения

* Использовался образ **centos/7** версии 2004.01

## Описание работы

* В репозиторий **GitHUB** добавлен [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_6/Vagrantfile),  который подключает 2 заранее отредактированных файла: спецификация для кастомной сборки **nginx** [nginx.spec](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_6/nginx.spec)
и конфигурационный файл web сервера  **nginx** [default.conf](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_6/default.conf),  а так же скрипт начальной настройки   
[rpmbngnx.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_6/rpmbngnx.sh):

```
sudo su && cd /root
```
Выполняется последовательно вход под суперпользователем и смена текущей директории на домашнюю рута
```
yum install  redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc -y
```
Устанавливаются в авторежиме (без вопросов) все необходимые для стенда пакеты (перечислены в методичке) + **gcc**, который не был указан, по сборка без него не идёт
```
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
```
скачивается SRPM пакет **nginx** и разворачивается в текущий каталог 
```
wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1m.tar.gz
tar -xvf openssl-1.1.1m.tar.gz
```
скачиваются и разворачиваются в текущий каталог исходники  **OpenSSL** актуальной версии

```
mv /root/rpmbuild/SPECS/nginx.spec /root/rpmbuild/SPECS/nginx.spec."$(date +%d-%m-%Y.%H.%M)" && cp /home/vagrant/nginx.spec /root/rpmbuild/SPECS/nginx.spec
```
дефолтная спецификация переименовывается и на её место копируется изменённая - с добавленным актуальным **OpenSSL**  с указанием локального расположения его исходников 
```
yum-builddep rpmbuild/SPECS/nginx.spec -y
```
устанавливаются требуемые пакеты для сборки **nginx** из спецификации

```
rpmbuild -bb rpmbuild/SPECS/nginx.spec
```
Старт сборки RPM пакета

```
yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
systemctl start nginx
```
Установка   кастомного **nginx** из полученного  RPM пакета и его запуск

```
mkdir /usr/share/nginx/html/repo
cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm
```
Создание внутри публичной веб папки директории для локального репозитория, копирование туда кастомного  **nginx** RPM пакета и скачивание туда же с  соответствующего web сервера RPM пакета ПО **percona**
```
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf."$(date +%d-%m-%Y.%H.%M)" && cp /home/vagrant/default.conf /etc/nginx/conf.d/default.conf
nginx -s reload
```
переименование дефолтной кофигурации вебсервера **nginx** и  на её место копируется изменённая, с указанием автоиндексации вложенных каталогов. Затем перезагрузка конфигурации **nginx**

```
echo -e "[otus]\nname=otus-linux\nbaseurl=http://localhost/repo\ngpgcheck=0\nenabled=1\n" >  /etc/yum.repos.d/otus.repo
```
создание файла-описания нового локального репозитория
```
createrepo /usr/share/nginx/html/repo/
```
инициализация локального репозитория в созданной ранее папке
```
yum install percona-release -y
```
установка стороннего приложения percona из RPM пакета, расположенного в локальном репозитории

## Результат работы 
  В результате получаем требуемый стенд 
```
1) создан свой RPM (nginx с актуальной версией OpenSSL)
2) создан свой репо с размещённым там своим RPM
```
