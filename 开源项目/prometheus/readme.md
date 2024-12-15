```
mkdir grafana_data prometheus_data && chmod 777 grafana_data prometheus_data
```

# 热更新配置文件
```
启动参数 --web.enable-lifecycle
http接口刷新热更新配置文件

curl -X POST http://172.22.220.21:9090/-/reload
```