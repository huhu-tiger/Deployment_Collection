
wget https://raw.githubusercontent.com/nginx/nginx/master/conf/mime.types
docker cp mime.types <nginx容器名>:/etc/nginx/mime.types