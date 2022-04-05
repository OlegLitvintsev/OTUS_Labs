# Лабораторная работа №11.  Первые шаги с Ansible.

## Настройка окружения

* В качестве хостовой OS использовалась Ubuntu 18.04 с установленными vagrant, virtualbox и ansible

## Порядок работы

### 1. Подготовка управляемой ansible гостевой VM
* в файле [Vagrantfile](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_11/Vagrantfile) определяем управляемую ansible гостевую VM
* стартуем гостевую VM
```
den@fwst:~/OTUS_Labs/Lab_11$ vagrant up
Bringing machine 'nginx' up with 'virtualbox' provider...
==> nginx: Importing base box 'centos/7'...
==> nginx: Matching MAC address for NAT networking...
==> nginx: Checking if box 'centos/7' version '2004.01' is up to date...
==> nginx: Setting the name of the VM: Lab_11_nginx_1649162010343_27145
==> nginx: Clearing any previously set network interfaces...
==> nginx: Preparing network interfaces based on configuration...
    nginx: Adapter 1: nat
    nginx: Adapter 2: hostonly
==> nginx: Forwarding ports...
    nginx: 22 (guest) => 2222 (host) (adapter 1)
==> nginx: Running 'pre-boot' VM customizations...
==> nginx: Booting VM...
==> nginx: Waiting for machine to boot. This may take a few minutes...
    nginx: SSH address: 127.0.0.1:2222
    nginx: SSH username: vagrant
    nginx: SSH auth method: private key
    nginx:
    nginx: Vagrant insecure key detected. Vagrant will automatically replace
    nginx: this with a newly generated keypair for better security.
    nginx:
    nginx: Inserting generated public key within guest...
    nginx: Removing insecure key from the guest if it's present...
    nginx: Key inserted! Disconnecting and reconnecting using new SSH key...
==> nginx: Machine booted and ready!
==> nginx: Checking for guest additions in VM...
    nginx: No guest additions were detected on the base box for this VM! Guest
    nginx: additions are required for forwarded ports, shared folders, host only
    nginx: networking, and more. If SSH fails on this machine, please install
    nginx: the guest additions and repackage the box to continue.
    nginx:
    nginx: This is not an error message; everything may continue to work properly,
    nginx: in which case you may ignore this message.
==> nginx: Setting hostname...
==> nginx: Configuring and enabling network interfaces...
==> nginx: Rsyncing folder: /home/den/OTUS_Labs/Lab_11/ => /vagrant
==> nginx: Running provisioner: shell...
    nginx: Running: inline script
```
* создаем файлы [ansible.cfg](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_11/ansible.cfg) и [staging/hosts](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_11/staging/hosts)
* проверяем возможность доступа ansible к управляемой VM
```
den@fwst:~/OTUS_Labs/Lab_11$ ansible nginx -m ping
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
den@fwst:~/OTUS_Labs/Lab_11$ ansible nginx -m command -a "uname -r"
nginx | CHANGED | rc=0 >>
3.10.0-1127.el7.x86_64
den@fwst:~/OTUS_Labs/Lab_11$ ansible nginx -m systemd -a name=firewalld
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "name": "firewalld",
    "status": {
        "ActiveEnterTimestampMonotonic": "0",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "inactive"                                                         
```

### 2. Установка **nginx** при помощи ansible в управляемую VM

* создаем файлы [templates/nginx.conf.j2](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_11/templates/nginx.conf.j2) и [nginx.yml](https://github.com/OlegLitvintsev/OTUS_Labs/blob/master/Lab_11/nginx.yml)
* начинаем установку **nginx**
```
den@fwst:~/OTUS_Labs/Lab_11$ ansible-playbook nginx.yml

PLAY [NGINX | Install and configure NGINX] ***************************************************************************************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************************************************************************************
ok: [nginx]

TASK [NGINX | Install EPEL Repo package from standart repo] **********************************************************************************************************************************************************************
changed: [nginx]

TASK [NGINX | Install NGINX package from EPEL Repo] ******************************************************************************************************************************************************************************
changed: [nginx]

TASK [NGINX | Create NGINX config file from template] ****************************************************************************************************************************************************************************
changed: [nginx]

RUNNING HANDLER [restart nginx] **************************************************************************************************************************************************************************************************
changed: [nginx]

RUNNING HANDLER [reload nginx] ***************************************************************************************************************************************************************************************************
changed: [nginx]

PLAY RECAP ***********************************************************************************************************************************************************************************************************************
nginx                      : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## Результат работы

* **nginx** работает в гостевой VM на порту 8080
```
den@fwst:~/OTUS_Labs/Lab_11$ curl http://192.168.11.150:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css">

        html {
        background-image:url(img/html-background.png);
        background-color: white;
        font-family: "DejaVu Sans", "Liberation Sans", sans-serif;
        font-size: 0.85em;
        line-height: 1.25em;
        margin: 0 4% 0 4%;
        }

        body {
        border: 10px solid #fff;
        margin:0;
        padding:0;
        background: #fff;
        }

        /* Links */

        a:link { border-bottom: 1px dotted #ccc; text-decoration: none; color: #204d92; }
        a:hover { border-bottom:1px dotted #ccc; text-decoration: underline; color: green; }
        a:active {  border-bottom:1px dotted #ccc; text-decoration: underline; color: #204d92; }
        a:visited { border-bottom:1px dotted #ccc; text-decoration: none; color: #204d92; }
        a:visited:hover { border-bottom:1px dotted #ccc; text-decoration: underline; color: green; }

        .logo a:link,
        .logo a:hover,
        .logo a:visited { border-bottom: none; }

        .mainlinks a:link { border-bottom: 1px dotted #ddd; text-decoration: none; color: #eee; }
        .mainlinks a:hover { border-bottom:1px dotted #ddd; text-decoration: underline; color: white; }
        .mainlinks a:active { border-bottom:1px dotted #ddd; text-decoration: underline; color: white; }
        .mainlinks a:visited { border-bottom:1px dotted #ddd; text-decoration: none; color: white; }
        .mainlinks a:visited:hover { border-bottom:1px dotted #ddd; text-decoration: underline; color: white; }

        /* User interface styles */

        #header {
        margin:0;
        padding: 0.5em;
        background: #204D8C url(img/header-background.png);
        text-align: left;
        }

        .logo {
        padding: 0;
        /* For text only logo */
        font-size: 1.4em;
        line-height: 1em;
        font-weight: bold;
        }

        .logo img {
        vertical-align: middle;
        padding-right: 1em;
        }

        .logo a {
        color: #fff;
        text-decoration: none;
        }

        p {
        line-height:1.5em;
        }

        h1 {
                margin-bottom: 0;
                line-height: 1.9em; }
        h2 {
                margin-top: 0;
                line-height: 1.7em; }

        #content {
        clear:both;
        padding-left: 30px;
        padding-right: 30px;
        padding-bottom: 30px;
        border-bottom: 5px solid #eee;
        }

    .mainlinks {
        float: right;
        margin-top: 0.5em;
        text-align: right;
    }

    ul.mainlinks > li {
    border-right: 1px dotted #ddd;
    padding-right: 10px;
    padding-left: 10px;
    display: inline;
    list-style: none;
    }

    ul.mainlinks > li.last,
    ul.mainlinks > li.first {
    border-right: none;
    }

  </style>

</head>

<body>

<div id="header">

    <ul class="mainlinks">
        <li> <a href="http://www.centos.org/">Home</a> </li>
        <li> <a href="http://wiki.centos.org/">Wiki</a> </li>
        <li> <a href="http://wiki.centos.org/GettingHelp/ListInfo">Mailing Lists</a></li>
        <li> <a href="http://www.centos.org/download/mirrors/">Mirror List</a></li>
        <li> <a href="http://wiki.centos.org/irc">IRC</a></li>
        <li> <a href="https://www.centos.org/forums/">Forums</a></li>
        <li> <a href="http://bugs.centos.org/">Bugs</a> </li>
        <li class="last"> <a href="http://wiki.centos.org/Donate">Donate</a></li>
    </ul>

        <div class="logo">
                <a href="http://www.centos.org/"><img src="img/centos-logo.png" border="0"></a>
        </div>

</div>

<div id="content">

        <h1>Welcome to CentOS</h1>

        <h2>The Community ENTerprise Operating System</h2>

        <p><a href="http://www.centos.org/">CentOS</a> is an Enterprise-class Linux Distribution derived from sources freely provided
to the public by Red Hat, Inc. for Red Hat Enterprise Linux.  CentOS conforms fully with the upstream vendors
redistribution policy and aims to be functionally compatible. (CentOS mainly changes packages to remove upstream vendor
branding and artwork.)</p>

        <p>CentOS is developed by a small but growing team of core
developers.&nbsp; In turn the core developers are supported by an active user community
including system administrators, network administrators, enterprise users, managers, core Linux contributors and Linux enthusiasts from around the world.</p>

        <p>CentOS has numerous advantages including: an active and growing user community, quickly rebuilt, tested, and QA'ed errata packages, an extensive <a href="http://www.centos.org/download/mirrors/">mirror network</a>, developers who are contactable and responsive, Special Interest Groups (<a href="http://wiki.centos.org/SpecialInterestGroup/">SIGs</a>) to add functionality to the core CentOS distribution, and multiple community support avenues including a <a href="http://wiki.centos.org/">wiki</a>, <a
href="http://wiki.centos.org/irc">IRC Chat</a>, <a href="http://wiki.centos.org/GettingHelp/ListInfo">Email Lists</a>, <a href="https://www.centos.org/forums/">Forums</a>, <a href="http://bugs.centos.org/">Bugs Database</a>, and an <a
href="http://wiki.centos.org/FAQ/">FAQ</a>.</p>

        </div>

</div>


</body>
</html>
```
