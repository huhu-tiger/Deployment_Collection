
```
# 创建本地目录
rm -rf data
for dir in data/7001 data/7002 data/7000; do [ -d "$dir" ] && rm -rf "$dir"; mkdir -p "$dir"; done
```


```
注意宿主机IP
sed -i 's/^cluster-announce-ip .*/cluster-announce-ip 172.22.220.21/' cluster-config/redis-node-7000.conf
sed -i 's/^cluster-announce-ip .*/cluster-announce-ip 172.22.220.21/' cluster-config/redis-node-7001.conf
sed -i 's/^cluster-announce-ip .*/cluster-announce-ip 172.22.220.21/' cluster-config/redis-node-7002.conf

docker-compose.yml up -d
```

# create redis-cluster
```
三个master 无副本
注意宿主机IP
进入容器执行
docker exec -it redis-7000 sh
redis-cli -a pass1234 --cluster create --cluster-replicas 0 \
172.22.220.21:7000 172.22.220.21:7001 172.22.220.21:7002


```