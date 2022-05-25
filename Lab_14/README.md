# Лабораторная работа №14. Docker

## Задача - cоздание образа nginx с модифицированной начальной страницей

1. Определите разницу между контейнером и образом

* Основное различие между образом и контейнером — в доступном для записи верхнем слое. Чтобы создать контейнер, движок Docker берет образ, добавляет доступный для записи верхний слой и инициализирует различные параметры (сетевые порты, имя контейнера, идентификатор и лимиты ресурсов). Все операции на запись внутри контейнера сохраняются в этом верхнем слое и когда контейнер удаляется, верхний слой, который был доступен для записи, также удаляется, в то время как нижние слоя остаются неизменными.

2. Можно ли в контейнере собрать ядро?

* ОС контейнера существует в виде образа и не является полноценной ОС, как система хоста. В образе есть только файловая система и бинарные файлы, а в полноценной ОС, помимо этого, есть ещё и ядро. Поэтому собрать ядро ОС в контейнере нельзя.

3. Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx) Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.

* Содержимое ```Dockerfile``` приведено ниже:

```
FROM nginx:alpine
RUN apk update && apk upgrade
COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/
EXPOSE 8080
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

В образе изменяются конфигурационный файл ```nginx.conf```, начальная веб страница сервера ```index.html``` и указывается порт привязки 8080

* Выполняется логин в свой реп докер хаба и далее сборка образа

```
docker login
docker build -t oglhb/ngnx:latest /home/den/OTUS_Labs/Lab_14/
```
* выполняется заливка образа в реп докерхаба

```
docker push oglhb/ngnx:latest
```

* Затем производится запуск контейнера и проверка результата работы
```
den@fwst:~/OTUS_Labs/Lab_14$ docker run -d -p 80:8080 oglhb/ngnx:latest
Unable to find image 'oglhb/ngnx:latest' locally
latest: Pulling from oglhb/ngnx
df9b9388f04a: Pull complete
a285f0f83eed: Pull complete
e00351ea626c: Pull complete
06f5cb628050: Pull complete
32261d4e220f: Pull complete
9da77f8e409e: Pull complete
c7061a74326a: Pull complete
76c168561419: Pull complete
b4a9ac10a4eb: Pull complete
Digest: sha256:f740bc5ccb31b4e18ca28e36a1039acb165531c6095b34f2be599aa1bd3d7f1f
Status: Downloaded newer image for oglhb/ngnx:latest
331f734344c2541cc632a4378d807b1efb1e83fad448457b8de48115e7a7850d
den@fwst:~/OTUS_Labs/Lab_14$
den@fwst:~/OTUS_Labs/Lab_14$
den@fwst:~/OTUS_Labs/Lab_14$ curl localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to MODIFIED nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to DOCKERED nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

* Измененный образ nginx доступен по [ссылке](https://hub.docker.com/repository/docker/oglhb/ngnx).

