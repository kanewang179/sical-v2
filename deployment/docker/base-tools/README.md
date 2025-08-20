# Sical Deploy 目录结构说明

本目录包含了构建 sical-deploy 镜像所需的所有文件，该镜像集成了 Jenkins 和 Kubernetes 基础工具，已按功能进行分类整理。

## 目录结构

```
base-tools/
├── Dockerfile              # 主要的镜像构建文件
├── kubectl                 # kubectl 二进制文件
├── README.md               # 本说明文件
├── build/                  # 构建相关目录（预留）
├── config/                 # 配置文件目录
│   ├── docker-compose.yml              # Sical Deploy 服务的 Docker Compose 配置
│   ├── docker-compose-standalone.yml   # Base Tools 独立部署配置
│   └── kind-config-docker-only.yaml    # Kind 集群配置文件
├── scripts/                # 脚本文件目录
│   ├── build.sh                        # 主构建脚本（sical-deploy镜像）
│   ├── build-jenkins-with-base-tools.sh # Jenkins 集成构建脚本（已废弃）
│   ├── build-standalone.sh             # Base Tools 独立构建脚本
│   ├── read-mirrors.sh                 # 镜像源配置读取脚本
│   └── setup-env.sh                    # 环境变量设置脚本
├── jenkins/                # Jenkins 相关文件
│   ├── jenkins-entrypoint.sh           # Jenkins 容器启动脚本
│   └── jenkins-init-kubectl.sh         # Jenkins 中 kubectl 初始化脚本
└── k8s/                    # Kubernetes 相关文件
    ├── healthcheck.sh                   # Kind 集群健康检查脚本
    ├── init-kind-cluster.sh            # Kind 集群初始化脚本
    └── k8s-resources/                   # Kubernetes 资源文件
        ├── configmap.yaml
        ├── frontend-deployment.yaml
        └── namespace.yaml
```

## 文件说明

### 核心文件
- **Dockerfile**: 构建包含 Jenkins 和 Kubernetes 工具的 sical-deploy 镜像
- **kubectl**: Kubernetes 命令行工具二进制文件

### 配置文件 (config/)
- **docker-compose.yml**: Sical Deploy 服务的完整部署配置
- **docker-compose-standalone.yml**: Base Tools 独立服务配置
- **kind-config-docker-only.yaml**: Kind 本地 Kubernetes 集群配置

### 构建脚本 (scripts/)
- **build.sh**: 主要构建脚本，构建集成了 Jenkins 和 Kubernetes 工具的 sical-deploy 镜像
- **build-jenkins-with-base-tools.sh**: Jenkins 与 Base Tools 集成构建（已废弃）
- **build-standalone.sh**: Base Tools 独立构建和部署
- **read-mirrors.sh**: 从 mirrors.json 读取镜像源配置
- **setup-env.sh**: 设置镜像源环境变量

### Jenkins 相关 (jenkins/)
- **jenkins-entrypoint.sh**: Jenkins 容器的启动入口脚本
- **jenkins-init-kubectl.sh**: 在 Jenkins 中初始化 kubectl 配置

### Kubernetes 相关 (k8s/)
- **healthcheck.sh**: Kind 集群健康状态检查
- **init-kind-cluster.sh**: 初始化 Kind Kubernetes 集群
- **k8s-resources/**: Kubernetes 资源定义文件

## 使用方法

### 构建镜像
```bash
# 构建 sical-deploy 镜像（包含 Jenkins 和 Kubernetes 工具）
./scripts/build.sh

# 仅构建 base-tools 镜像
./scripts/build-standalone.sh
```

### 启动服务
```bash
# 启动 Sical Deploy 服务（包含 Jenkins 和 Kubernetes 工具）
docker-compose -f config/docker-compose.yml up -d

# 启动独立的 base-tools 服务
docker-compose -f config/docker-compose-standalone.yml up -d
```

### 健康检查
```bash
# 检查 Kind 集群状态
./k8s/healthcheck.sh
```

## 镜像架构

本项目现在采用单层集成架构：
1. **sical-deploy**: 集成了 Jenkins 和 Kubernetes 工具（kubectl, helm, kustomize, kind）的完整部署镜像
2. **base-tools**: 独立的 Kubernetes 工具镜像（可选）

这种架构的优势：
- 一体化部署，简化使用
- 包含完整的 CI/CD 和 Kubernetes 管理功能
- 减少镜像依赖关系
- 便于快速部署和使用