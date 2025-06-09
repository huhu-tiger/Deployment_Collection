docker pull sonatype/nexus3:3.80.0-java17-alpine
mkdir  data
sudo chmod -R 777  data
docker-compose  up -d
第一次查看 密码
```
docker exec -ti nexus3 sh -c "cat /nexus-data/admin.password"
```