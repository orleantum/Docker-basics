# Лаб 5. Docker basics - практика

# Задание:

Создать образ и запустить контейнер:
- внутри которого будет работать веб-сервер Nginx,
- отдающий статическую html страницу с приветствием с порта,
- для доступа снаружи к nginx по сети пробросить в контейнер порт 54321
- команду запуска контейнера оформить шелл-скриптом
- Сгенерировать SSL сертификат
- Запускать nginx в контейнере с HTTPS протоколом, с сертификатом
- Сертификат пробросить в контейнер через Volume Mapping
- Сделать скрипт обновления (пересоздания сертификата), который будет давать внутрь докера команду nginx на перечитывание сертификата (reload)

### Пробросил порты

<img width="686" height="199" alt="image" src="https://github.com/user-attachments/assets/14d7286c-c8a1-410d-9161-68879a62aa73" />


### `Dockerfile`

```Dockerfile
FROM nginx:1.30.3-alpine

COPY ./index.html /var/www/html/index.html
COPY ./nginx-conf/nginx.conf /etc/nginx/conf.d/default.conf

RUN nginx -t

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
```


### `nginx-conf/nginx.conf`

```nginx
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        index index.html index.html index.nginx-debian.html;

        server_name _;

        location / {
                try_files $uri $uri/ =404;
        }
}
```


### `index.html`

```HTML
<!DOCTYPE html>
<html>
  <head>
    <title>DevOps Ops Ops 2024</title>
  </head>
<body>
Ops Ops 2024!
</body>
</html>
```


### Сборка образа

```Bash
sudo docker build -t nginx-image .
```

<img width="771" height="923" alt="image" src="https://github.com/user-attachments/assets/aad519ef-7ea9-4c60-b2ba-d2539de4e74d" />


### Запуск контейнера

```Bash
sudo docker run -d -p 80:80 --name nginx-container nginx-image
```

<img width="856" height="44" alt="image" src="https://github.com/user-attachments/assets/a321e69e-849d-4b86-a909-3bc5233af08f" />

<img width="932" height="97" alt="image" src="https://github.com/user-attachments/assets/8323be7c-7cb3-4b8b-82c8-6f2a82b0b52e" />


```Bash
sudo docker logs -n 10 nginx-container
```

<img width="932" height="270" alt="image" src="https://github.com/user-attachments/assets/100b00a5-cfcb-41ba-a43c-057482b9e053" />


### Проверка доступа

<img width="458" height="196" alt="image" src="https://github.com/user-attachments/assets/5bf0173c-048f-4624-9656-2f6ecb96feb7" />

<img width="252" height="84" alt="image" src="https://github.com/user-attachments/assets/5bc6c5f7-e8ff-4390-becc-5cb3bec0e2e4" />


# Написание скрипта

### `deploy.sh`

```BASH
#!/bin/bash

IMAGE_NAME="nginx-image"
CONTAINER_NAME="nginx-container"
PORT="80"

if [ "$(sudo docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
    sudo docker stop $CONTAINER_NAME > /dev/null
    sudo docker rm $CONTAINER_NAME > /dev/null
fi

if [ "$(sudo docker images -q $IMAGE_NAME)" ]; then
    sudo docker rmi $IMAGE_NAME > /dev/null
fi

# Сборка нового образа
sudo docker build -t $IMAGE_NAME .

# Выход если образ не собрался
if [ $? -ne 0 ]; then
    exit 1
fi

# Запуск контейнера
sudo docker run -d -p $PORT:80 --name $CONTAINER_NAME $IMAGE_NAME

# Выход если контейнер не запустился
if [ $? -ne 0 ]; then
    exit 1
fi

# Проверка доступности сайта
curl http://localhost:$PORT
```

Выдача прав на исполнение:

```Bash
chmod +x deploy.sh
```


### Запуск скрипта

<img width="607" height="948" alt="image" src="https://github.com/user-attachments/assets/4916d572-6631-4b19-9b0b-ca43cc3be61f" />


# Дополнительное задание:

- Сгенерировать SSL сертификат
- Запускать nginx в контейнере с HTTPS протоколом, с сертификатом
- Сертификат пробросить в контейнер через Volume Mapping
- Сделать скрипт обновления (пересоздания сертификата), который будет давать внутрь докера команду nginx на перечитывание сертификата (reload)

### Изменим файл `nginx-conf/nginx.conf`

```nginx
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;

        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        root /var/www/html;

        index index.html index.html index.nginx-debian.html;

        server_name _;

        location / {
                try_files $uri $uri/ =404;
        }
}
```


### Генерация сертификатов:

```Bash
mkdir certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout certs/nginx.key -out certs/nginx.crt -subj "/C=RU/ST=Perm/L=Perm/O=DevOpsLab/CN=localhost"
```

<img width="934" height="151" alt="image" src="https://github.com/user-attachments/assets/9e372f45-5ba7-450f-844a-9c32bee2983e" />


- **/C=RU** (Country) - Страна. Двухбуквенный код страны по международному стандарту.
- **/ST=Perm** (State) - Регион (край, область, штат).
- **/L=Perm** (Locality) - Город или населенный пункт.
- **/O=iadiyanov** (Organization) - Название организации или компании.
- **/CN=localhost** (Common Name) - Доменное имя (или IP-адрес) сервера, для которого выпускается сертификат.


### Скрипт обновления сертификатов `renew_certs.sh`

```Bash
#!/bin/bash

CONTAINER_NAME="nginx-container"

# Перезаписываем старые ключи новыми
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/nginx.key -out certs/nginx.crt \
  -subj "/C=RU/ST=Perm/L=Perm/O=DevOpsLab/CN=localhost" > /dev/null 2>&1

# Выполнение команды внутри запущенного контейнера
sudo docker exec $CONTAINER_NAME nginx -s reload
```

Выдача прав на исполнение:

```Bash
chmod +x renew_certs.sh
```


### Обновим скрипт `deploy.sh`:

```Bash
#!/bin/bash

IMAGE_NAME="nginx-image"
CONTAINER_NAME="nginx-container"
HTTP_PORT="80"
HTTPS_PORT="443"

if [ "$(sudo docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
    sudo docker stop $CONTAINER_NAME > /dev/null
    sudo docker rm $CONTAINER_NAME > /dev/null
fi

if [ "$(sudo docker images -q $IMAGE_NAME)" ]; then
    sudo docker rmi $IMAGE_NAME > /dev/null
fi

# Сборка нового образа
sudo docker build -t $IMAGE_NAME .

# Выход если образ не собрался
if [ $? -ne 0 ]; then
    exit 1
fi

# Запуск контейнера
sudo docker run -d -p $HTTP_PORT:80 -p $HTTPS_PORT:443 \
  -v $(pwd)/certs:/etc/nginx/ssl \
  --name $CONTAINER_NAME $IMAGE_NAME

# Выход если контейнер не запустился
if [ $? -ne 0 ]; then
    exit 1
fi

# Время на запуск Nginx
sleep 3

# Проверка доступности сайта
curl http://localhost:$HTTP_PORT
curl -k https://localhost:$HTTPS_PORT
```


### Пробросим порт

<img width="687" height="201" alt="image" src="https://github.com/user-attachments/assets/bfb088ff-a51f-468a-b914-48bb83e9e4ca" />


### Запуск и проверка

<img width="778" height="783" alt="image" src="https://github.com/user-attachments/assets/ebd0f6a0-2b89-41ea-822a-8ef0f269459c" />

<img width="685" height="614" alt="image" src="https://github.com/user-attachments/assets/4ac0e78b-5830-4f38-9a9a-4edeb84c41e3" />

<img width="394" height="98" alt="image" src="https://github.com/user-attachments/assets/d4facd55-c3b3-4e4c-9798-8d419c0e7fb3" />


# Итоговая структура проекта

<img width="275" height="270" alt="{A1C9DF5A-342F-414D-B1BB-5008478F32B7}" src="https://github.com/user-attachments/assets/f414aad7-c83e-4311-a6e0-c7c6e0a7ff02" />
