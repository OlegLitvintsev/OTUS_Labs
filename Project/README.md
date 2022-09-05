# Проектная работа - развертывание инфраструктуры WEB-портала на базе CMS Wordress 

## Задача - развертывание и настройка инфраструктуры в соответствии со следующими требованиями:

* включен https (разрешено использование самоподписанных сертификатов);
* основная инфраструктура в DMZ зоне;
* файрвалл на входе;
* сбор метрик и настроенный алертинг;
* везде включен selinux;
* организован централизованный сбор логов;
* организован backup.

## Для организации WEB-портала развертывается инфраструктурная схема из 4-х виртуальных серверов:

[Схема][https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Project/imgs/scheme.PNG]

* **inetrouter** - сервер приема входящих соединений для Frontend WordPress и Zabbix, осуществляется NAT-ирование, проброс порта TCP 443 до сервера **wordpress** и порта TCP 8080 до сервера **monlog**, установлено ПО:
  * rsyslog - для репликации логов на сервер **monlog**;
  * Zabbix agent - для мониторинга сервером Zabbix (**monlog**).
* **backup** - сервер резервного копирования, установлено ПО:
  * BorgBackup для организации локального хранилища резервных копий и осуществления резерного копирования/восстановления по запросам от BorgBackup на серверах **wordpress** и **monlog**;
  * rsyslog - для репликации логов на сервер **monlog**;
  * Zabbix agent - для мониторинга сервером Zabbix (**monlog**).
* **monlog** - сервер системы мониторинга Zabbix и централизованного сбора логов rsyslog, установлено ПО:
  * Zabbix Server - для мониторинга серверов портала;
  * MySQL Server - база данных для Zabbix Server;
  * NGINX - web сервер для Zabbix Server;
  * Percona XtraBackup для осуществления резерного копирования базы данных MySQL Zabbix;
  * BorgBackup для осуществления резерного копирования на сервер резервного копирования **backup**;
  * rsyslog - для централизованного сбора и хранения логов серверов портала.
* **wordpress** - сервер CMS WordPress, установлено ПО:
  * Wordpress - CMS WordPress;
  * MySQL Server - база данных для WordPress;
  * NGINX - web сервер для WordPress;
  * Percona XtraBackup для осуществления резерного копирования базы данных MySQL Zabbix;
  * BorgBackup для осуществления резерного копирования на сервер резервного копирования **backup**;
  * rsyslog - для репликации логов на сервер **monlog**;
  * Zabbix agent - для мониторинга сервером Zabbix (**monlog**).

### **Vagrant**, в соответствии с [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Project/Vagrantfile), развертывает 4 виртуальные машины, **provision** которых выполняется при помощи **playbook Ansible** [playbook.yml](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Project/playbook.yml), выполняющий 4 роли, имеющие имена, соответствующие именам развертываемых ими серверов. Селекция ролей относительно серверов осуществляется метками **tags** в соответствующих разделах **provision** [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Project/Vagrantfile).

