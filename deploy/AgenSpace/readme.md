# 部署手册

该目录提供基于 Docker Compose 的 **MySQL + Nacos** 独立部署方案，并包含自动化初始化脚本。

## 目录结构

- `docker-compose.middleware.yml`：MySQL / Nacos 以及初始化容器编排文件
- `config/mysql/`
  - `my.cnf`：MySQL 自定义配置
  - `mysql-schema.sql`：根据 Nacos 版本准备的初始化 SQL（默认指向 2.5.1）
  - `init.sql`：保留脚本，可按需扩展
- `scripts/`
  - `init_mysql.sh`：等待 MySQL ready，创建 `nacos_config` 库并导入 SQL（已存在时跳过）
  - `init_nacos.sh`：等待 Nacos ready，使用 Admin API 初始化 `nacos` 用户密码（重复执行返回 409 时视为成功）
  - `test_nacos.sh`：健康检测 + 示例 API 调用脚本，可快速验证服务

## 前置准备

1. **安装依赖**
   - Docker ≥ 20.10
   - Docker Compose v2

2. **配置 `.env`**（此文件不随仓库提供，需要自行创建）
   ```env
   # MySQL
   AGENT_SPACE_MYSQL_IMAGE=mysql:8.0.44
   MYSQL_PASSWORD=你的_mysql_root密码

   # Nacos
   AGENT_SPACE_NACOS_IMAGE=model.vnet.com/sjhl/nacos-server:v2.5.1
   NACOS_PASSWORD=你的_nacos新密码
   NACOS_AUTH_TOKEN=随机构造>=32位字符串并再Base64
   NACOS_AUTH_IDENTITY_KEY=serveridentity
   NACOS_AUTH_IDENTITY_VALUE=security

   # 初始化容器复用的镜像
   AGENT_SPACE_INIT_IMAGE=model.vnet.com/sjhl/nacos-server:v2.5.1
   ```

3. **准备 Nacos 初始化 SQL**
   - 如果使用不同版本，请从官方仓库下载对应 `mysql-schema.sql` 并覆盖 `config/mysql/mysql-schema.sql`
   ```bash
   wget https://github.com/alibaba/nacos/blob/2.5.1/distribution/conf/mysql-schema.sql -O config/mysql/mysql-schema.sql
   ```

## 启动步骤

1. **进入目录**
   ```bash
   cd /data/deploy/AgenSpace/nacos_mysql
   ```

2. **启动 MySQL & Nacos**
   ```bash
   docker compose --profile app up -d
   ```
   > 该命令会按以下顺序启动：
   > - `agent-space-mysql`：MySQL 主库
   > - `agent-space-mysql-init`：等待 MySQL ready，创建数据库并导入 schema（只运行一次，成功后退出）
   > - `agent-space-nacos-mysql`：Nacos 服务器，依赖前两者正常完成
   > - `agent-space-nacos-init`：等待 Nacos ready，通过 `/v1/auth/users/admin` 初始化 `nacos` 用户密码

3. **查看运行状态**
   ```bash
   docker compose ps
   ```
   - `agent-space-mysql-init` 与 `agent-space-nacos-init` 在成功执行后会以退出状态显示，可忽略

4. **验证服务**
   ```bash
   # 首次执行需要赋权
   chmod +x scripts/test_nacos.sh

   NEW_USERNAME=nacos NEW_PASSWORD=abc!@111 ./scripts/test_nacos.sh
   ```
   - 脚本将检查健康状态，并尝试调用 `/v1/auth/users` 接口创建/更新用户

## 常见操作

- **停止服务**：`docker compose --profile app down`
- **清理 MySQL 数据目录**（会重置数据）：
  ```bash
  docker compose --profile app down
  rm -rf data/mysql
  ```
- **手动执行初始化脚本**：
  ```bash
  docker compose run --rm agent-space-mysql-init
  docker compose run --rm agent-space-nacos-init
  ```

## Nacos 启动参数说明

| 参数 | 描述 |
| ---- | ---- |
| `NACOS_AUTH_TOKEN` | JWT 签名密钥，长度需 > 32，建议再做 Base64 编码 |
| `NACOS_AUTH_IDENTITY_KEY` | Nacos Server 之间内部通讯的身份标识 Key |
| `NACOS_AUTH_IDENTITY_VALUE` | Nacos Server 之间内部通讯的身份标识 Value |

## 常见问题

- **初始化脚本重复执行返回 409**：表示密码已初始化，脚本会输出提示并正常退出
- **网络错误 `network ... not found`**：执行 `docker compose down` 后，可手动 `docker network prune -f`
- **需要更换初始化 SQL**：下载对应版本的 schema 文件并替换 `config/mysql/mysql-schema.sql`

如需进一步定制，可根据实际业务调整镜像、端口、环境变量或挂载目录。