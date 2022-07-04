# Лабораторная работа №16. PAM

## Задачи

- Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников


## Решение 

* Разворачиваем Вагрантом хост **pamc**, провижном на нем создаётся группа **admin** в которую добавляется пользователь **vagrant**
	
* для решения задачи используется модуль **pam_exec**, для чего в файл ```/etc/pam.d/sshd``` провижном добавляется строка
```
account    required     pam_exec.so stdout /usr/local/bin/test_login.sh
``` 

* Cкрипт ```/usr/local/bin/test_login.sh``` также создаётся при провижне и его содержание приведено ниже

```
#!/bin/bash                                                                                        
echo -e "\nhello, "$PAM_USER"\nYour group list is\n"$(id -Gn $PAM_USER)                            
if [ $(date +%u) -ge 5 ]; then                                                                     
        echo "today is weekend, "                                                                    
        if [ $(id -Gn $PAM_USER | grep "admin" | wc -l) -gt 0 ]; then                              
                echo "welcome!"                                                        
                exit 0                                                                             
        else                                                                                       
                echo "bye!"                                             
        exit 1                                                                                     
        fi                                                                                         
else                                                                                               
        echo "welcome!"                                                 
        exit 0                                                                                     
fi                                                                                                 
```

## Проверка работы.

* Входим на хост в рабочий день
 ```
den@fwst:~/OTUS_Labs/Lab_16$ vagrant ssh

hello, vagrant
Your group list is
vagrant admin
today is weekday, welcome!
 ```
	
* Меняем на  хосте **pamc** дату на выходной ```date +%Y%m%d -s "20220709"``` и повторяем попытку, пока пользователь состоит в группе **admin** 
 ```
den@fwst:~/OTUS_Labs/Lab_16$ vagrant ssh

hello, vagrant
Your group list is
vagrant admin
today is weekend,
welcome!
 ```

* Удаляем пользователя **vagrant** из группы  **admin** ```gpasswd -d vagrant admin```  и повторяем попытку входа, которая заканчивается неудачей

