FROM nginx:1.30.3-alpine

COPY ./index.html /var/www/html/index.html
COPY ./nginx-conf/nginx.conf /etc/nginx/conf.d/default.conf

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
