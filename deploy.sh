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
