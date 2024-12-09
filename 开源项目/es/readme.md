# run sysctl.conf

# .env

# 创建本地目录
```
mkdir -p certs esdata01 esdata02 esdata03 kibanadata
```

# 修改 instances.yml IP

# 中文分词
(download)[https://release.infinilabs.com/analysis-ik/stable/]
```
wget https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-8.1.3.zip
mkdir -p plugins/ik
mv elasticsearch-analysis-ik-8.1.3.zip plugins/ik
cd plugins/ik
unzip elasticsearch-analysis-ik-8.1.3.zip
cd ../../
```

```
docker-compose -f docker-compose.yml up -d
```

#kibana login
```
elastic/pass12345
```

#kibana 中的devTools菜单
```
GET _analyze
{
  "analyzer": "ik_smart",
  "text": "程序员青年阿福2023年发表的文章集合"
}
```
pydev/Elasticsearch_demo/demo.py

