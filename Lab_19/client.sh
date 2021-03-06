#!/bin/bash
echo -e "\n***********************************************************************"
echo -e "***********Provision script on "$(hostname)
echo -e "***********************************************************************\n\n"
yum install wget -y
wget https://github.com/borgbackup/borg/releases/download/1.1.18/borg-linux64 -O /usr/local/bin/borg
chmod +x /usr/local/bin/borg
echo -e "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEAzJT45S1Uj7SFiKtA8gH51TV97aniBL/OZ8PXz/qW4KJDah6a\n8VF15zS8dlhBil9q7VVDxfbbDHPtN07PAto0YqEqBzWYfWWBEpcyqAUykjV4HEVO\nFbBZsMe74CCKTlXc4qniKah5PHTUsWvyWqwpV4ygyJDKpTUZyIFcR+BSADu0iV5U\ncyjNeWLNpdJq5ZOdPG2BsxcL24K8URzTWIMzI4F/9Ha3Vyo+HHq7qwRirnAOE4K8\nxQ/SihTu+1Z+A+sSFFqC2LW46GXIFqYaIps0TR7W6QR0ON8iO9CALp+dCUdP5ZWg\nyyeq7L9YkNHSFvhd+FVTakySR4W84W0h64K6iwIDAQABAoIBAEUfRGUyhrKzPLbr\nndrm3gGyvCST1KDkKZoXqpBDy7yENqDhTFqiumJvCAo4UZSuHpOnzmlRubsgZBLe\n1sTQ8wgsCeY7rpUXuZ+NZHkuoGKUHEv5AqQDXJqFMa5NcE19Z09SNO78VFIf60ky\n/sSyDJnfEugRO9bL9TUwt/w1B5+58ZIkHNncBCItI94PLFv/4Qza3UUZifpOq3P8\nyGqDVXJqEWsc6UxypplvZScRBLJ2o029k/L3y53SQ2jO/nkcUGpizNkzVOJBAMes\ndgQuZQx6MqwRI3TZWDjJUcS8jaX+rJgfy0wGW6Iw2abn9GrztDam7aRa62Iu8fm9\n245xiKkCgYEA9CtNgB/x2KX6MyYlzxIaWfBG2hzUJs2YnhoUt22duJLXhQ1fs6au\nBjkgiNzJIFj6HAW83PoDpet9wYKm7EZJOCj4oIncff6z8/RJVs8rdCLEkzf9yRJa\nk6fGBbGY4T2R0OYMUVKBuSmD9or5F/Tlg6FJE0ea0KYSnuWPJX3pVp8CgYEA1n6g\nMzs8/cuLN5/5z0V/y11PD0Sy+tZj3EMfOhDX3DDflG78+UqtgNOp8ODR54yyQ1kP\nmokAVC+4SUlxKJoSiEcSZd/nsTZHBpdTCyjuyFotsbdu4wmbAgzZcOFfujScmRUm\nvwcNPHn2g7oCcqDIfT64rsLzDqCOP9yhcrUasJUCgYBGM+kdjJHBo78zU6WNSvwu\nncoRTjalTXmzA3avYqH1fqrew4Cfq63fdi9nimt9lHec9P1fX7cKzpGiwMjzqCXH\nMuiBaAHwa/obi0JG5lvtEU4JshCS7mcCizuBSZXWNRimwm4KN7m6njgl+8Ew5SXU\nWdwj4fOeSBGUhBZLRk9/qwKBgQC0rrn4LgB0sg817jaa2SqLfrBoZjB2iD5afthB\nK4sKWskb2lqTDMsW6DYRSPDIooZPoSg5vwpd4EzWv1zpHNBbp7Lhyjj72IMAFFzJ\n29M5Rm2TdLed3KuMkJJiOhdPXZ5EfcLDzAbkWMDFudzx/mqkxj8ASAxC2BC7zvjZ\nDaHL+QKBgG8dl3dYfMtD9+wVj80fZXvDsXYtVFCMT9oVHKAAhqDt4i/GbL9A5mlo\njkJJ4QTnLLSmOIjSBUuSDab0vBLrynZ8xlyJaotP4n5hl3Qki96kQno5UXcyu2Kq\n3uZgvo9tEQKueypM2Fu7fCb0pnPhPSQF427jZnWrUJPcFUyYrvvY\n-----END RSA PRIVATE KEY-----" > ~vagrant/.ssh/id_rsa 
mkdir /root/.ssh && cp /home/vagrant/.ssh/id_rsa /root/.ssh/ &&  chmod 400 /root/.ssh/id_rsa && chown vagrant:vagrant /home/vagrant/.ssh/id_rsa && chmod 400 /home/vagrant/.ssh/id_rsa
ssh-keyscan -H ,192.168.11.150 > /home/vagrant/.ssh/known_hosts && ssh-keyscan -H ,192.168.11.150 > /root/.ssh/known_hosts && chown vagrant:vagrant /home/vagrant/.ssh/known_hosts
#borg init --encryption=repokey-blake2  borg@192.168.11.150:/var/backup/client
chmod +x /home/vagrant/backup.sh
(crontab -l ; echo -e "*/5 * * * * /home/vagrant/backup.sh\n") | sort - | uniq - | crontab - 

