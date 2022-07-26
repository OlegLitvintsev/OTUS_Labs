# Лабораторная работа № 20. Настройка PXE сервера для автоматической установки

## Задание: настроить PXE сервер для автоматической установки по HTTP

-  Цель: Отрабатываем навыки установки и настройки DHCP, TFTP, PXE загрузчика и автоматической загрузки

1. Следуя шагам из документа https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install установить и настроить загрузку по сети для дистрибутива CentOS8
В качестве шаблона воспользуйтесь репозиторием https://github.com/nixuser/virtlab/tree/main/centos_pxe
2. Поменять установку из репозитория NFS на установку из репозитория HTTP
3. Настроить автоматическую установку для созданного kickstart файла


## Решение

* В репозиторий **GitHUB** добавлен модифицированный согласно заданию [Vagrant файл](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_20/Vagrantfile),  который  разворачивает **PXE сервер** и клиентскую станцию, получающую адрес и информацию о загрузчике по DHCP. Посредством модифицированного шелл скрипта [setup_pxe.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_20/setup_pxe.sh) вместо **NFS** в нём устанавливается и настраивается **nginx**. Также меняются пути репозиториев инсталляций в файле конфигурации меню загрузки. Запуск формирования виртуальных машин осуществляется скриптом [start.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_20/start.sh), устанавливающим переменную окружения ```export VAGRANT_EXPERIMENTAL="disks"```, необходимую для использования расширения Vagrant в целях добавления места для скачивания 9 Гб файла инсталляционного образа CentOS 8

* После старта обоих виртуальных машин наблюдаем на консоли виртуальной машины клиентской станции меню PXE загрузчика
![Меню PXE загрузчика](/Lab_20/imgs/PXE_boot_menu.jpg)

* Нажав **Enter** или подождав 60 секунд, после нескольких минут загрузки, получаем окно инсталлятора CentOS 8
![Запуск инсталлятора CentOS 8](/Lab_20/imgs/PXE_CentOS8_installation.png)

* При необходимости автоматической инсталляции CentOS 8 нужно перед созданием виртуальных машин переместить в скрипте [setup_pxe.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_20/setup_pxe.sh) строку ```menu default``` из секции ```LABEL linux``` в секцию ```LABEL linux-auto```
