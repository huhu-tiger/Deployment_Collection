# run sysctl.conf

# .env

# 创建本地目录
```
for dir in certs esdata01 esdata02 esdata03 kibanadata; do [ -d "$dir" ] && rm -rf "$dir"; mkdir -p "$dir"; done

```

# 修改 instances.yml IP

# 中文分词
(download)[https://release.infinilabs.com/analysis-ik/stable/]
```
version=8.7.1
wget https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-${version}.zip
mkdir -p plugins/ik
mv elasticsearch-analysis-ik-${version}.zip plugins/ik
pushd plugins/ik
unzip elasticsearch-analysis-ik-${version}.zip
popd

```

```
docker-compose -f docker-compose.yml up -d
```

#查看集群状态
```
https://10.20.201.212:9200/_cat/nodes?v
https://10.20.201.212:9200/_cat/nodes?v
https://10.20.201.212:9200/_cat/nodes?v

elastic/Elastic!2025
```


#kibana login
```
elastic/Elastic!2025
```

#kibana 中的devTools菜单
```
GET _analyze
{
  "analyzer": "ik_smart",
  "text": "程序员青年阿福2023年发表的文章集合"
}
```





pydev/Elasticsearch_demo/demo.py #预先copy ca.crt

