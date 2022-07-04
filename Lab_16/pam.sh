#!/bin/bash
echo "Provision script"
groupadd admin && usermod vagrant -G admin
echo -e '#!/bin/bash\necho -e "\\nhello, "$PAM_USER"\\nYour group list is\\n"$(id -Gn $PAM_USER)\nif [ $(date +%u) -ge 5 ]; then\n\techo "today is weekend, "\n\tif [ $(id -Gn $PAM_USER | grep "admin" | wc -l) -gt 0 ]; then\n\t\techo "welcome!"\n\t\texit 0\n\telse\n\t\techo "bye!"\n\texit 1\n\tfi\nelse\n\techo "today is weekday, welcome!"\n\texit 0\nfi' > /usr/local/bin/test_login.sh  && chmod +x /usr/local/bin/test_login.sh
sed -i 's/pam_nologin.so/pam_nologin.so\naccount    required     pam_exec.so stdout \/usr\/local\/bin\/test_login.sh/' /etc/pam.d/sshd

