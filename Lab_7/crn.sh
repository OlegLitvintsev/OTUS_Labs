(crontab -l ; echo -e "0 * * * * /home/vagrant/anlog.sh\n") | sort - | uniq - | crontab -

