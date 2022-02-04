# Лабораторная работа №2.  Дисковая подсистема. 

## Настройка окружения

* Лабораторная работа выполнялась в среде Hyper-V Windows 2016 Server, в котором включена вложенная виртуализация командлетом PowerShell
  ```  
  Set-VMProcessor -VMName <VMName> -ExposeVirtualizationExtensions $true 
  ```
* В качестве хостовой OS использовалась Ubuntu 18.04 LTS
* Использовался образ [CentOS-7.7](https://app.vagrantup.com/OlegLitvintsev/boxes/CentOS-7.7), полученный в результате выполнения лабораторной работы № 1

## Ход выполнения и возникшие проблемы

* Команда  `mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}` завершается с ошибкой `Unrecognised md component device  - /dev/sd(b-f)`. RAID5 успешно собирается и без нее, а поскольку сборка всегда происходит при одинаковых условиях во время первого запуска виртуальной машины, команда исключена из скрипта построения RAID.

## Результат работы

* В репозиторий GitHUB добавлен bash скрипт ([MakeRAID5.sh](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_2/MakeRAID5.sh)) создания RAID5, конфигурационный файл для автосборки RAID5 при загрузке ([mdadm.conf](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_2/mdmadm.conf)) и [Vagrant файл](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_2/Vagrantfile), который собирает RAID5 при первом запуске виртуальной машины.

