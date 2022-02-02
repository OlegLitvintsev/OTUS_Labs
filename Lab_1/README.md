# Лабораторная работа №1.  Обновление ядра. 

## Настройка окружения

* Лабораторная работа выполнялась в среде Hyper-V Windows 2016 Server, в котором включена вложенная виртуализация командлетом PowerShell
  ```  
  Set-VMProcessor -VMName <VMName> -ExposeVirtualizationExtensions $true 
  ```
* В качестве хостовой OS использовалась Ubuntu 18.04 LTS
* Установлены актуальные версии Oracle VirtualBox, HashiCorp Vagrant, HashiCorp Packer, Git
* Была создана учетная запись  https://app.vagrantup.com/OlegLitvintsev  в Vagrant cloud и учетная запись в GitHUB https://github.com/OlegLitvintsev
* Для доступа к репозиторию GitHUB был добавлен SSН ключ

## Ход выполнения и возникшие проблемы

* Образ ввиду отсутствия на yandex был взят с https://vault.centos.org/7.7.1908/isos/x86_64/CentOS-7-x86_64-Minimal-1908.iso
* С целью гарантированного выполнения скрипта на высоконагруженном стенде, были увеличены значения тайм-аутов в centos.json
```
{
  "variables": {
    "artifact_description": "CentOS 7.7 with kernel 5.x",
    "artifact_version": "7.7.1908",
    "image_name": "centos-7.7"
  },

  "builders": [
    {
      "name": "{{user `image_name`}}",
      "type": "virtualbox-iso",
      "vm_name": "packer-centos-vm",

      "boot_wait": "25s",
      "disk_size": "10240",
      "guest_os_type": "RedHat_64",
      "http_directory": "http",

      "iso_url": "https://vault.centos.org/7.7.1908/isos/x86_64/CentOS-7-x86_64-Minimal-1908.iso",
      "iso_checksum": "9a2c47d97b9975452f7d582264e9fc16d108ed8252ac6816239a3b58cef5c53d",

      "boot_command": [
        "<tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant.ks<enter><wait>"
      ],

      "shutdown_command": "sudo -S /sbin/halt -h -p",
      "shutdown_timeout" : "10m",

      "ssh_wait_timeout": "35m",
      "ssh_username": "vagrant",
      "ssh_password": "vagrant",
      "ssh_port": 22,
      "ssh_pty": true,

      "output_directory": "builds",

      "vboxmanage": [
        [  "modifyvm",  "{{.Name}}",  "--memory",  "1048" ],
        [  "modifyvm",  "{{.Name}}",  "--cpus",  "2" ]
      ],

      "export_opts":
      [
        "--manifest",
        "--vsys", "0",
        "--description", "{{user `artifact_description`}}",
        "--version", "{{user `artifact_version`}}"
      ]

    }
  ],

  "post-processors": [
    {
      "output": "centos-{{user `artifact_version`}}-kernel-5-x86_64-Minimal.box",
      "compression_level": "7",
      "type": "vagrant"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "execute_command": "{{.Vars}} sudo -S -E bash '{{.Path}}'",
      "start_retry_timeout": "3m",
      "expect_disconnect": true,
      "pause_before": "45s",
      "override": {
        "{{user `image_name`}}" : {
          "scripts" :
            [
              "scripts/stage-1-kernel-update.sh",
              "scripts/stage-2-clean.sh"
            ]
        }
      }
    }
  ] 
``` 


## Результат работы

* В репозиторий Vagrant cloud добавлен билд с обновлённым ядром версии **5.8.0-1.el7.elrepo.x86_64** по адресу https://app.vagrantup.com/OlegLitvintsev/boxes/CentOS-7.7
* В репозиторий GitHUB добавлено описание лабораторной работы, оформленной в разметке **Markdown** по адресу https://github.com/OlegLitvintsev/OTUS_Labs/Lab_1/README.md
* В репозиторий GitHUB добавлен **Vagrantfile**, загружающий образ виртуальной машины с https://app.vagrantup.com/OlegLitvintsev/boxes/CentOS-7.7
