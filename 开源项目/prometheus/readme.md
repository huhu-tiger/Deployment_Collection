```
[ ! -d grafana_data ] && mkdir grafana_data; [ ! -d prometheus_data ] && mkdir prometheus_data; chmod 777 grafana_data prometheus_data

```

# 热更新配置文件
```
配置权限，宿主司和容器文件同步
chmod -R 777 prometheus
chmod -R 777 prometheus_data

启动参数 --web.enable-lifecycle
http接口刷新热更新配置文件

curl -X POST http://{prometheus_ip}:9090/-/reload
```