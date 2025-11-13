# ComfyUI Docker 部署文档

## 项目简介

本项目使用 Docker Compose 部署 ComfyUI，支持多 GPU 节点和负载均衡。

## 环境变量配置

### 必需的环境变量

创建 `.env` 文件，配置以下变量：

```bash
# ComfyUI 镜像
COMFYUI_AI_IMAGE=your-comfyui-image:tag

# Nginx 镜像
NGINX_AI_IMAGE=your-nginx-image:tag
```

### 容器环境变量说明

#### Role（角色）
- **master**: 主节点，负责初始化 vnet 目录和 server.py，执行依赖安装
- **其他值或未设置**: 工作节点，仅执行依赖安装

#### PYTHONPATH_CUSTOM_PATH
- Python 自定义库安装路径，默认为 `/data/python_libs`
- 用于安装 vnet 和自定义节点的依赖包

#### 代理配置
- `HTTP_PROXY`: HTTP 代理地址
- `HTTPS_PROXY`: HTTPS 代理地址  
- `NO_PROXY`: 不使用代理的地址列表（逗号分隔）

#### CLI_ARGS
- ComfyUI 启动参数
- 默认: `--disable-smart-memory --enable-cors-header '*' --user-directory=/root/ComfyUI/user`

## Docker Compose Profiles 说明

### Profiles 列表

- **app**: 启动所有应用服务（包括 GPU 节点和 Nginx）
- **comfyui**: ComfyUI 相关服务
- **gpu**: 所有 GPU 节点
- **gpu0**: 第一个 GPU 节点（主节点，Role=master）
- **gpu1**: 第二个 GPU 节点（工作节点）
- **lb**: 负载均衡服务
- **nginx**: Nginx 反向代理服务

### 常用启动命令

```bash
# 启动所有服务
docker-compose --profile app up -d

# 仅启动第一个 GPU 节点（用于初始化）
docker-compose --profile gpu0 up -d

# 启动所有 GPU 节点
docker-compose --profile gpu up -d

# 仅启动 Nginx
docker-compose --profile nginx up -d
```

## 部署操作

### 首次部署（更新 vnet 目录、server.py 或第一次启动）

```bash
# 1. 停止所有服务
docker-compose --profile app down

# 2. 清理存储目录（可选，会删除所有数据）
rm -rf storage
mkdir storage

# 3. 先启动主节点进行初始化
docker-compose --profile gpu0 up -d

# 4. 等待主节点初始化完成（检查日志）
docker logs -f comfyui-0

# 5. 启动所有服务
docker-compose --profile app up -d
```

### 重启服务

```bash
# 停止所有服务
docker-compose --profile app down

# 启动所有服务
docker-compose --profile app up -d
```

### 查看服务状态

```bash
# 查看所有服务状态
docker-compose --profile app ps

# 查看日志
docker logs -f comfyui-0  # 主节点
docker logs -f comfyui-1  # 工作节点
docker logs -f comfyui-app-nginx  # Nginx
```

### 添加新的自定义节点（Custom Nodes）

当需要添加新的 ComfyUI 自定义节点时，需要修改 `user-scripts/pre-start.sh` 文件中的 `install_custom_nodes()` 函数。

#### 操作步骤

1. **编辑 pre-start.sh 文件**

   打开 `user-scripts/pre-start.sh` 文件，找到 `install_custom_nodes()` 函数。

2. **添加新节点安装代码**

   在函数中添加新节点的安装逻辑，参考以下模板：

   ```bash
   install_custom_nodes() {
       pushd $comfyui_customnodes_dir
       
       # 节点1: ComfyUI-QwenVL
       if [ -d "ComfyUI-QwenVL" ]; then
           echo "[INFO] ComfyUI-QwenVL 已存在，跳过安装。"
       else
           echo "[INFO] 正在安装 ComfyUI-QwenVL..."
           git clone https://github.com/1038lab/ComfyUI-QwenVL.git
           cd ComfyUI-QwenVL
           if [ -f "requirements.txt" ]; then
               disable_proxy
               pip install -r requirements.txt -i $pip_source -t $PYTHONPATH_CUSTOM_PATH
               restore_proxy
           fi
           cd ..
       fi
       # 创建模型目录（如果需要）
       mkdir -p /root/ComfyUI/models/custom_nodes/ComfyUI-QwenVL
       
       # 节点2: 新节点名称（示例）
       if [ -d "新节点目录名" ]; then
           echo "[INFO] 新节点目录名 已存在，跳过安装。"
       else
           echo "[INFO] 正在安装 新节点名称..."
           git clone https://github.com/用户名/仓库名.git
           cd 新节点目录名
           if [ -f "requirements.txt" ]; then
               disable_proxy
               pip install -r requirements.txt -i $pip_source -t $PYTHONPATH_CUSTOM_PATH
               restore_proxy
           fi
           cd ..
       fi
       # 创建模型目录（如果需要）
       mkdir -p /root/ComfyUI/models/custom_nodes/新节点目录名
       
       popd
   }
   ```

3. **配置模型目录挂载（如果节点需要模型文件）**

   在 `docker-compose.gpu.yml` 中为需要模型目录的节点添加挂载配置：

   ```yaml
   # 在 comfyui_gpu0 和 comfyui_gpu1 的 volumes 部分添加：
   volumes:
     # ... 其他挂载 ...
     - "/media/llm/lightx2v/models/custom_nodes/新节点目录名:/root/ComfyUI/models/custom_nodes/新节点目录名"
   ```

   在宿主机上创建对应的模型目录：

   ```bash
   mkdir -p /media/llm/lightx2v/models/custom_nodes/新节点目录名
   ```

4. **保存文件并重启服务**

   ```bash
   # 停止所有服务
   docker-compose --profile app down
   
   # 启动服务（会自动执行 pre-start.sh 安装新节点）
   docker-compose --profile app up -d
   ```

5. **验证安装**

   ```bash
   # 查看安装日志
   docker logs comfyui-0 | grep -E "INFO|正在安装"
   
   # 检查节点目录是否存在
   docker exec comfyui-0 ls -la /root/ComfyUI/custom_nodes/
   ```

#### 模型目录配置

如果自定义节点需要下载模型文件，需要配置模型目录挂载：

1. **在 docker-compose.gpu.yml 中添加模型目录挂载**

   在对应服务的 `volumes` 部分添加：
   ```yaml
   volumes:
     # ... 其他挂载 ...
     - "/media/llm/lightx2v/models/custom_nodes/{节点目录}:/root/ComfyUI/models/custom_nodes/{节点目录}"
   ```
   
   例如，如果节点名为 `ComfyUI-QwenVL`，则添加：
   ```yaml
   - "/media/llm/lightx2v/models/custom_nodes/ComfyUI-QwenVL:/root/ComfyUI/models/custom_nodes/ComfyUI-QwenVL"
   ```

2. **创建模型目录**

   在宿主机上创建对应的模型目录：
   ```bash
   mkdir -p /media/llm/lightx2v/models/custom_nodes/{节点目录}
   ```

3. **在安装脚本中创建模型目录（可选）**

   如果需要在安装节点时自动创建模型目录，可以在 `install_custom_nodes()` 函数中添加：
   ```bash
   # 创建节点模型目录
   mkdir -p /root/ComfyUI/models/custom_nodes/{节点目录}
   ```

#### 注意事项

- **目录检查**: 脚本会检查节点目录是否已存在，如果存在则跳过安装，避免重复安装
- **依赖安装**: 如果节点有 `requirements.txt` 文件，会自动安装依赖包
- **代理处理**: 依赖安装时会自动取消代理（使用 `disable_proxy`），安装完成后恢复（使用 `restore_proxy`）
- **安装路径**: 依赖包会安装到 `$PYTHONPATH_CUSTOM_PATH` 目录（默认为 `/data/python_libs`）
- **模型目录**: 自定义节点的模型文件应放在 `/root/ComfyUI/models/custom_nodes/{节点目录}` 目录下，对应宿主机路径为 `/media/llm/lightx2v/models/custom_nodes/{节点目录}`
- **模型目录挂载**: 如果节点需要模型文件，需要在 `docker-compose.gpu.yml` 中添加相应的目录挂载配置
- **手动安装**: 如果自动安装失败，可以进入容器手动安装：
  ```bash
  docker exec -it comfyui-0 bash
  cd /root/ComfyUI/custom_nodes
  git clone https://github.com/用户名/仓库名.git
  cd 仓库名
  pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple -t /data/python_libs
  # 如果需要模型目录
  mkdir -p /root/ComfyUI/models/custom_nodes/节点目录名
  ```

#### 示例：添加 ComfyUI-Manager

**1. 在 pre-start.sh 中添加安装代码：**

```bash
# 在 install_custom_nodes() 函数中添加：
# ComfyUI-Manager
if [ -d "ComfyUI-Manager" ]; then
    echo "[INFO] ComfyUI-Manager 已存在，跳过安装。"
else
    echo "[INFO] 正在安装 ComfyUI-Manager..."
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git
    cd ComfyUI-Manager
    if [ -f "requirements.txt" ]; then
        disable_proxy
        pip install -r requirements.txt -i $pip_source -t $PYTHONPATH_CUSTOM_PATH
        restore_proxy
    fi
    cd ..
fi
```


## 目录结构说明

### 挂载目录

- `./storage:/root` - ComfyUI 主目录和数据存储
- `./user-scripts:/root/user-scripts` - 用户脚本目录（包含 pre-start.sh）
- `/media/llm/lightx2v/models:/root/ComfyUI/models` - 模型文件目录
- `./gpu0/input:/root/ComfyUI/input` - GPU0 输入目录
- `./gpu0/output:/root/ComfyUI/output` - GPU0 输出目录
- `./gpu1/input:/root/ComfyUI/input` - GPU1 输入目录
- `./gpu1/output:/root/ComfyUI/output` - GPU1 输出目录
- `/media/llm/lightx2v/models/custom_nodes/{节点目录}` - 自定义节点时需要下载的模型目录
- `./workflows:/root/ComfyUI/user/default/workflows` - 工作流文件
- `./extends:/root/extends` - 扩展文件（vnet、server.py 等）
- `./data/python_libs:/data/python_libs` - Python 自定义库目录

### 重要文件

- `user-scripts/pre-start.sh` - 容器启动前执行的脚本
  - 自动安装 vnet 依赖
  - 自动安装自定义节点（ComfyUI-QwenVL）
  - 仅在 Role=master 时执行初始化操作

## 端口说明

- **80**: Nginx HTTP 端口
- **81**: Nginx 管理端口
- **8180**: ComfyUI GPU0 代理端口
- **8181**: ComfyUI GPU1 代理端口
- **8188**: ComfyUI 内部服务端口（容器内）

## 注意事项

1. **首次启动**: 必须使用 `--profile gpu0` 先启动主节点，确保初始化完成后再启动其他服务
2. **Role 设置**: 只有 Role=master 的容器会执行初始化操作，其他容器仅安装依赖
3. **存储目录**: `storage` 目录包含 ComfyUI 的所有数据，删除前请备份
4. **代理配置**: 如果网络环境不需要代理，可以移除或注释 docker-compose.gpu.yml 中的代理配置
5. **自定义节点**: ComfyUI-QwenVL 会在首次启动时自动安装，如果目录已存在则跳过

## 故障排查

### 查看初始化日志

```bash
# 查看主节点启动日志
docker logs comfyui-0 | grep -E "INFO|ERROR"

# 查看 pre-start.sh 执行情况
docker exec comfyui-0 cat /root/user-scripts/pre-start.sh
```

### 手动执行初始化

如果自动初始化失败，可以手动执行：

```bash
docker exec -it comfyui-0 bash
cd /root/user-scripts
bash pre-start.sh
```
