
```shell
修改 yum.repo

yum install -y wget vim
wget https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/static/stable/x86_64/docker-20.10.24.tgz

tar xvf docker-20.10.24.tgz
chmod +x docker/*
mv docker/* /usr/bin/
```


```shell
cat << EOF | sudo tee /usr/lib/systemd/system/docker.service > /dev/null
[Unit]

Description=Docker Application Container Engine

Documentation=https://docs.docker.com

After=network-online.target firewalld.service

Wants=network-online.target



[Service]

Type=notify

ExecStart=/usr/bin/dockerd

ExecReload=/bin/kill -s HUP \$MAINPID

LimitNOFILE=infinity

LimitNPROC=infinity

TimeoutStartSec=0

Delegate=yes

KillMode=process

Restart=on-failure

StartLimitBurst=3

StartLimitInterval=60s



[Install]

WantedBy=multi-user.target
EOF

chmod +x /usr/lib/systemd/system/docker.service

systemctl daemon-reload
```

```shell
mkdir -p /etc/docker/
mkdir -p /data/docker
cat <<EOF >/etc/docker/daemon.json
{
    "data-root": "/data/docker",
    "registry-mirrors": [
        "https://docker.1ms.run",
        "https://docker.xuanyuan.me"
    ],
    "insecure-registries":["0.0.0.0/0"],
    "live-restore": true,
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "50m",
      "max-file": "3"
    },
    "default-address-pools": [
    {
      "base": "172.30.0.0/16",
      "size": 24
    },
    {
      "base": "172.31.0.0/16",
      "size": 24
    }
  ]
}
EOF

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

docker info|grep -i root
```

## docker-compose install
```shell
wget  https://github.com/docker/compose/releases/download/v2.27.2/docker-compose-linux-x86_64 -O /usr/bin/docker-compose && chmod +x /usr/bin/docker-compose
```

## docker hub hosts
```shell
echo -e "\n59.151.19.44\tmodel.vnet.com" | sudo tee -a /etc/hosts

```