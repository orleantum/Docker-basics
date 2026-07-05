#!/bin/bash

CONTAINER_NAME="nginx-container"

# Перезаписываем старые ключи новыми
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/nginx.key -out certs/nginx.crt \
  -subj "/C=RU/ST=Perm/L=Perm/O=DevOpsLab/CN=localhost" > /dev/null 2>&1

# Выполнение команды внутри запущенного контейнера
sudo docker exec $CONTAINER_NAME nginx -s reload
