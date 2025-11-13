

# 注意事项
使用外部nacos 在.env中配置外部nacos令牌

# 安装步骤
## 初始化数据
```
docker compose --profile init up
...
postcheck-1    | All good!
postcheck-1 exited with code 0
...
```


# Higress 部署手册（Docker Compose）

## 1. 前置条件

- 已安装 Docker ≥ 20.10、Docker Compose v2
- 服务器放通端口（按需）：
  - 网关对外：80/tcp、443/tcp、15020/tcp
  - 控制台：8080/tcp
  - 监控：Prometheus 9090（内部）、Grafana 3000（内部）、Loki 3100（内部）
- 已有可用的外部 Nacos（推荐 MySQL 持久化），并确认 Higress 容器网络可访问该 Nacos 地址

目录结构（节选）：

```
/data/deploy/AgenSpace/higress
  ├─ docker-compose.yml
  ├─ readme.md
  ├─ env/
  │   ├─ controller.env
  │   ├─ gateway.env
  │   ├─ nacos.env   # 仅用于内置 nacos（默认已禁用）
  │   ├─ pilot.env
  │   └─ promtail.env
  ├─ scripts/
  │   └─ init.sh
  └─ volumes/        # 首次运行后由初始化流程创建/填充
```


## 2. 配置 .env（同目录自动读取）

在 `AgenSpace/higress` 目录创建或编辑 `.env`，至少设置以下变量（示例）：

```
# 核心：配置后端使用外部 Nacos
CONFIG_STORAGE=nacos
NACOS_SERVER_URL=http://192.168.33.91:8848/nacos
NACOS_NS=higress-system
NACOS_USERNAME=nacos
NACOS_PASSWORD=你的密码

# 加密密钥（重要）
# 说明：apiserver 会读取 ./volumes/api/nacos.key。若设置此值将写入固定密钥；
# 若留空且允许随机密钥，请将 NACOS_USE_RANDOM_DATA_ENC_KEY != N。
NACOS_DATA_ENC_KEY=固定的32+长度字符串（复用老环境时必须一致）
NACOS_USE_RANDOM_DATA_ENC_KEY=Y   # 使用随机密钥并执行“已有配置检查”；复用老配置改为 N

# 组件镜像版本（示例，可按需调整）
HIGRESS_RUNNER_TAG=v1.0.0
HIGRESS_API_SERVER_TAG=v1.0.0
HIGRESS_CONTROLLER_TAG=v1.0.0
HIGRESS_PILOT_TAG=v1.20.4
HIGRESS_GATEWAY_TAG=v1.20.4
PROMETHEUS_TAG=v2.53.0
PROMTAIL_TAG=2.9.0
LOKI_TAG=3.1.1
GRAFANA_TAG=11.2.0

# 对外端口（需要对外暴露时可调整）
GATEWAY_HTTP_PORT=80
GATEWAY_HTTPS_PORT=443
GATEWAY_METRICS_PORT=15020
CONSOLE_PORT=8080

# 本地文件根目录（如需挂载外部配置，可变更为绝对路径）
FILE_ROOT_DIR=./volumes/dummy
```

变量含义补充：
- `NACOS_DATA_ENC_KEY`：用于生成/覆盖 `./volumes/api/nacos.key` 的固定密钥，apiserver 用它加密存储在 Nacos 中的敏感配置。复用已有配置时必须与旧环境一致。
- `NACOS_USE_RANDOM_DATA_ENC_KEY`：当不使用固定密钥时（值不等于 `N`），脚本会生成随机密钥并检查目标 namespace 是否已有 Higress 配置，若已存在会中止以避免密钥不一致导致的启动失败。设置为 `N` 表示使用固定密钥并跳过此检查。


## 3. 使用外部 Nacos 的额外说明

- `docker-compose.yml` 中内置 `nacos` 服务已注释，不会启动本地 Nacos。外部 Nacos 地址由 `NACOS_SERVER_URL` 提供。
- 若使用 HTTPS Nacos，需要确保 `./volumes/api` 下的证书配置满足连接要求，并将 `NACOS_SERVER_URL` 改为 `https://...`。
- 确保 Higress 容器网络能直通 Nacos（防火墙/安全组/路由策略等）。


## 4. 初始化与启动

1) 进入目录：
```
cd /data/deploy/AgenSpace/higress
```

2) 可选：运行初始化流程（生成所需卷文件，如 `nacos.key` 等）。这一步会启动 `initializer` 并在完成后退出：
```
docker compose --profile init up
```
执行完成出现 `initializer` 退出即可结束（Ctrl+C）。

3) 启动核心组件（后台运行）：
```
docker compose up -d
```

Compose 会按依赖顺序启动：`precheck → apiserver → prepare → controller → pilot → gateway → console → prometheus → promtail → loki → grafana → postcheck`。全部健康后，`postcheck` 输出 “All good!” 并退出（code 0）。


## 5. 验证与健康检查

- 查看服务：
```
docker compose ps
```

- 查看某服务日志：
```
docker compose logs -f apiserver
docker compose logs -f gateway
docker compose logs -f controller
```

- 控制台访问：
  - 浏览器打开：`http://<主机IP>:8080`（可在 `.env` 中通过 `CONSOLE_PORT` 修改对外端口）

- 网关探针端点（内部）：
  - `http://127.0.0.1:15021/healthz/ready`（容器内或通过端口映射）


## 6. 常用操作

- 更新镜像版本后拉取并重启：
```
docker compose pull
docker compose up -d
```

- 查看/跟随全部日志：
```
docker compose logs -f
```

- 停止并保留数据：
```
docker compose down
```

- 清理并重建（谨慎：可能重置监控等数据卷）：
```
docker compose down
rm -rf volumes/grafana/lib volumes/prometheus/data volumes/loki/data
```


## 7. 故障排查

- 外部 Nacos 不通：
  - 用 `docker exec -it <apiserver容器> sh` 进入容器内，`curl` 访问 `NACOS_SERVER_URL`，确认网络与 URL 正确。
  - 如用 HTTPS，检查证书与服务器时间；必要时在 `./volumes/api` 放置根证书并配置。

- 启动报错提示 namespace 已存在配置：
  - 发生于使用随机密钥（`NACOS_USE_RANDOM_DATA_ENC_KEY != N`）且目标 namespace 已有 Higress 配置时。按提示清空该 namespace 配置，或切换 namespace，或改为使用固定密钥并确保与历史一致。

- 控制台无法登录/无数据：
  - 确认 `apiserver` 健康；确认 `NACOS_*` 账号密码与 namespace 正确。
  - 查看 `controller`、`pilot`、`gateway` 日志是否报拉取配置/下发失败。

- 端口占用：
  - 修改 `.env` 中 `GATEWAY_HTTP_PORT`、`GATEWAY_HTTPS_PORT`、`CONSOLE_PORT` 等端口再 `up -d`。


## 8. 升级与回滚

1) 修改 `.env` 中各镜像 TAG 或新增变量；  
2) 执行：
```
docker compose pull
docker compose up -d
```
3) 若异常，回退至上一个稳定 TAG 并重复上述两步；必要时配合备份/恢复 `volumes`。


## 9. 附：关键环境变量说明

- `NACOS_SERVER_URL`：外部 Nacos 地址，若是 2.x 默认控制台路径一般为 `/nacos`。
- `NACOS_NS`：Higress 配置使用的 Nacos 命名空间 ID。
- `NACOS_USERNAME` / `NACOS_PASSWORD`：Nacos 认证信息。
- `NACOS_DATA_ENC_KEY`：用于生成/覆盖 `./volumes/api/nacos.key` 的密钥（复用旧环境必须一致）。
- `NACOS_USE_RANDOM_DATA_ENC_KEY`：是否使用随机密钥并执行已有配置检查（`N` 表示固定密钥并跳过检查）。
- `FILE_ROOT_DIR`：本地挂载的数据根目录（`initializer`/`prepare` 等脚本会使用）。

