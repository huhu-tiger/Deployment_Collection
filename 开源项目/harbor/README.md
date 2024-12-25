# 安装harbor

## 下载离线安装包介质

```shell
wget https://objects.githubusercontent.com/github-production-release-asset-2e65be/50613991/806eb4e2-6da8-42f1-888f-29d44c0d9a96?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=releaseassetproduction%2F20241224%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20241224T071356Z&X-Amz-Expires=300&X-Amz-Signature=1c0a3201039ad2974b27efeba583dbf30545efa5bc94c52f6f2696516f7d27e1&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3Dharbor-offline-installer-v2.12.1.tgz&response-content-type=application%2Foctet-stream
```

得到离线文件：harbor-offline-installer-v2.12.1.tgz

参考：https://goharbor.io/docs/2.12.0/install-config/download-installer/

## 前置条件

1. docker >=20.10.10-ce+
2. docker compose: docker-compose (v1.18.0+) or docker compose v2 (docker-compose-plugin)
3. 检查80端口是否被占用
4. 检查是否启动了同名的容器: nginx、redis、registry、registryctl、harbor-*

参考：https://goharbor.io/docs/2.12.0/install-config/installation-prereqs/

## 配置

```shell
tar -zxvf harbor-offline-installer-v2.12.1.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml
```

修改harbor.yml文件

```shell
注释掉https相关配置
# https related config
# https:
  # https port for harbor, default is 443
  # port: 443
  # The path of cert and key files for nginx
  # certificate: /your/certificate/path
  # private_key: /your/private/key/path
  # enable strong ssl ciphers (default: false)
  # strong_ssl_ciphers: false
```

## 启动Harbor

```shell
host=xxxx ./install.sh
```

运行结果：

````
[+] Running 10/10
 ✔ Network harbor_harbor        Created                                                                        0.1s 
 ✔ Container harbor-log         Started                                                                        0.7s 
 ✔ Container registry           Started                                                                        0.9s 
 ✔ Container redis              Started                                                                        1.2s 
 ✔ Container registryctl        Started                                                                        1.1s 
 ✔ Container harbor-db          Started                                                                        1.1s 
 ✔ Container harbor-portal      Started                                                                        1.2s 
 ✔ Container harbor-core        Started                                                                        1.4s 
 ✔ Container nginx              Started                                                                        1.7s 
 ✔ Container harbor-jobservice  Started                                                                        1.6s 
````

会使用/data目录存储harbor相关数据。同时把harbor文件夹内生成common目录和docker-compose.yml文件。

# 登陆配置

访问http://xxx能够访问到harbor页面，登陆密码为：admin/Harbor12345。

找到用户管理，创建用户

![](./user.jpg)

然后创建项目

![](./project.png)

给zhongzi项目增加vnet用户权限。

![](./add_user.png)

创建机器人账户，设置推送和拉取权限。

![](./robot.png)

# 客户端访问

## 登陆

```shell
echo "H9VwgT7l1VPtbOGN4K2gvhNxU1d7sGeE" | docker login 192.168.33.85 -u robot\$zhongzi+robot --password-stdin
```

根据实际情况，替换要登录的harbor地址192.168.33.85和密码。

## 推送

```shell
docker push 192.168.33.85/zhongzi/nginx:stable-alpine3.17-perl
```

## 拉取

```shell
docker pull 192.168.33.85/zhongzi/nginx:stable-alpine3.17-perl
```

