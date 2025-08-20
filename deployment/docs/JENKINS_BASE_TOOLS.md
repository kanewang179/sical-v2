# Jenkins 基于 Base-Tools 镜像部署指南

## 概述

本文档介绍如何使用基于 `base-tools` 镜像构建的 Jenkins 镜像。这种方式的优势是：

1. **减少重复下载**：kubectl、helm、kind 等工具在 base-tools 镜像中预先安装
2. **提高构建效率**：避免每次构建 Jenkins 镜像时重复下载工具
3. **版本一致性**：确保所有服务使用相同版本的 Kubernetes 工具
4. **镜像复用**：base-tools 镜像可以被其他服务复用

## 架构说明

```
base-tools:latest (Alpine + kubectl + helm + kind + kustomize)
    ↓
jenkins-github:base-tools (Jenkins LTS + base-tools 工具)
```

## 构建步骤

### 1. 使用构建脚本（推荐）

```bash
# 进入项目根目录
cd /path/to/sical-v2

# 运行构建脚本
./deployment/docker/build-jenkins-with-base-tools.sh
```

构建脚本会自动：
- 检查必要文件
- 构建 base-tools 镜像
- 基于 base-tools 构建 Jenkins 镜像
- 验证工具安装

### 2. 手动构建

```bash
# 1. 构建 base-tools 镜像
docker build -f deployment/docker/Dockerfile.base-tools -t base-tools:latest .

# 2. 构建 Jenkins 镜像
docker build \
    --build-arg BASE_TOOLS_IMAGE=base-tools:latest \
    -f deployment/docker/jenkins/Dockerfile.base-tools \
    -t jenkins-github:base-tools .
```

## 部署方式

### 使用 Docker Compose（推荐）

```bash
# 启动服务
docker-compose -f deployment/docker/docker-compose-jenkins-base-tools.yml up -d

# 查看日志
docker-compose -f deployment/docker/docker-compose-jenkins-base-tools.yml logs -f

# 停止服务
docker-compose -f deployment/docker/docker-compose-jenkins-base-tools.yml down
```

### 使用 Docker 命令

```bash
# 启动 Jenkins 容器
docker run -d \
    --name jenkins-github-base-tools \
    -p 8080:8080 \
    -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    jenkins-github:base-tools
```

## 验证安装

### 检查工具版本

```bash
# 进入容器
docker exec -it jenkins-github-base-tools bash

# 验证工具
kubectl version --client
helm version
kind version
docker --version
node --version
npm --version
```

### 检查 Jenkins 状态

```bash
# 检查容器状态
docker ps | grep jenkins-github-base-tools

# 检查健康状态
docker inspect jenkins-github-base-tools | jq '.[0].State.Health'
```

## 与原版本的对比

| 特性 | 原版本 (Dockerfile) | Base-Tools 版本 |
|------|-------------------|------------------|
| 构建时间 | 较长（需下载所有工具） | 较短（复用预安装工具） |
| 镜像大小 | 较大 | 相对较小 |
| 工具版本一致性 | 每次构建可能不同 | 统一管理 |
| 网络依赖 | 高（每次下载） | 低（预安装） |
| 维护复杂度 | 低 | 中等 |

## 故障排除

### 1. 构建失败

```bash
# 检查 base-tools 镜像是否存在
docker images | grep base-tools

# 如果不存在，先构建 base-tools
docker build -f deployment/docker/Dockerfile.base-tools -t base-tools:latest .
```

### 2. kubectl 不可用

```bash
# 检查 kubectl 是否正确复制
docker run --rm jenkins-github:base-tools which kubectl
docker run --rm jenkins-github:base-tools kubectl version --client
```

### 3. Docker 权限问题

```bash
# 检查 Docker socket 权限
ls -la /var/run/docker.sock

# 修复权限（如果需要）
sudo chmod 666 /var/run/docker.sock
```

## 配置说明

### 环境变量

- `JAVA_OPTS`: Jenkins JVM 参数
- `DOCKER_HOST`: Docker 守护进程地址
- `BASE_TOOLS_IMAGE`: base-tools 镜像名称

### 挂载点

- `/var/jenkins_home`: Jenkins 数据目录
- `/var/run/docker.sock`: Docker socket
- `/workspace`: 工作空间（可选）

### 端口

- `8080`: Jenkins Web UI
- `50000`: Jenkins 代理连接端口

## 最佳实践

1. **定期更新 base-tools**：保持工具版本最新
2. **版本标签**：为镜像添加版本标签便于管理
3. **资源限制**：在生产环境中设置适当的资源限制
4. **备份策略**：定期备份 Jenkins 数据
5. **安全配置**：配置适当的网络和访问控制

## 相关文件

- `deployment/docker/Dockerfile.base-tools`: Base-tools 镜像定义
- `deployment/docker/jenkins/Dockerfile.base-tools`: Jenkins 镜像定义
- `deployment/docker/build-jenkins-with-base-tools.sh`: 构建脚本
- `deployment/docker/docker-compose-jenkins-base-tools.yml`: Docker Compose 配置
- `deployment/mirrors.json`: 镜像源配置