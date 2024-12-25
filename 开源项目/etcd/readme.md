# 创建本地目录
```
for dir in etcd1 etcd2 etcd3; do [ -d "$dir" ] && rm -rf "$dir"; mkdir -p "$dir"; done

```

#客户端
```
https://github.com/evildecay/etcdkeeper
https://github.com/tzfun/etcd-workbench
```