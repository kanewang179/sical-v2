# SICAL-V2 部署指南

## 概述

本文档提供了 SICAL-V2 项目的完整部署指南，包括 Docker-only 环境的配置、Kind 集群的设置、Jenkins CI/CD 流水线的配置等。

## 架构概览

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Jenkins       │    │   Kind Cluster  │    │  Local Registry │
│   (CI/CD)       │────│   (Kubernetes)  │────│   (Images)      │
│   Port: 8080    │    │   Port: 6443    │    │   Port: 5000    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Docker Network │
                    │ sical-docker-   │
                    │   only-network  │
                    └─────────────────┘
```

## 前置要求

### 系统要求
- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB 可用内存
- 至少 10GB 可用磁盘空间

### 必需工具
```bash
# 验证 Docker 安装
docker --version
docker-compose --version

# 验证系统资源
docker system df
free -h
```

## 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd sical-v2
```

### 2. 构建基础镜像
```bash
# 构建 base-tools 镜像
docker build -f deployment/docker/Dockerfile.base-tools -t base-tools:latest .

# 构建 Jenkins 镜像
docker build \
    --build-arg BASE_TOOLS_IMAGE=base-tools:latest \
    -f deployment/docker/jenkins/Dockerfile.base-tools \
    -t jenkins-github:base-tools .
```

### 3. 启动服务
```bash
cd deployment/docker

# 启动所有服务
docker-compose -f docker-compose-docker-only.yml up -d

# 查看服务状态
docker-compose -f docker-compose-docker-only.yml ps
```

### 4. 验证部署
```bash
# 检查服务健康状态
docker-compose -f docker-compose-docker-only.yml ps

# 访问 Jenkins
open http://localhost:8080

# 检查 Kind 集群
docker exec kind-cluster kubectl get nodes
```

## 详细配置

### Kind 集群配置

#### 配置文件: `kind-config-docker-only.yaml`
- **集群名称**: `sical-cluster`
- **API 服务器端口**: `6443`
- **Ingress 端口**: `80`, `443`
- **特性门控**: `EphemeralContainers`, `HPAScaleToZero`

#### 初始化脚本: `init-kind-cluster.sh`
- 启动 systemd 和 kubelet 服务
- 等待 API 服务器启动
- 生成并配置 kubeconfig
- 等待系统 Pod 启动完成

### Jenkins 配置

#### 镜像构建
- **基础镜像**: `jenkins/jenkins:lts`
- **工具来源**: `base-tools:latest`
- **包含工具**: kubectl, helm, kind, kustomize, docker-compose

#### 初始化配置
- **kubectl 配置**: 自动连接到 Kind 集群
- **Docker 访问**: 通过 Docker Socket
- **Git 配置**: 优化 GitHub 连接

#### 环境变量
```bash
JENKINS_OPTS=--httpPort=8080
DOCKER_HOST=unix:///var/run/docker.sock
KUBECONFIG=/var/jenkins_home/.kube/config
GITHUB_TOKEN=${GITHUB_TOKEN:-}
GITHUB_WEBHOOK_SECRET=${GITHUB_WEBHOOK_SECRET:-}
```

### Docker Registry 配置

#### 本地镜像仓库
- **端口**: `5000`
- **存储**: Docker Volume
- **健康检查**: HTTP 端点检查

## 服务启动顺序

1. **Registry** - 本地镜像仓库
2. **Kind Cluster** - Kubernetes 集群
3. **Jenkins** - CI/CD 服务（依赖前两者健康状态）

### 依赖关系配置
```yaml
jenkins-github:
  depends_on:
    registry:
      condition: service_healthy
    kind-cluster:
      condition: service_healthy
```

## 网络配置

### Docker 网络
- **网络名称**: `sical-docker-only-network`
- **驱动**: `bridge`
- **服务通信**: 通过服务名称

### 端口映射
| 服务 | 内部端口 | 外部端口 | 描述 |
|------|----------|----------|------|
| Jenkins | 8080 | 8080 | Web UI |
| Jenkins | 50000 | 50000 | Agent 连接 |
| Registry | 5000 | 5000 | 镜像仓库 |
| Kind API | 6443 | 6443 | Kubernetes API |
| Kind HTTP | 80 | 80 | Ingress HTTP |
| Kind HTTPS | 443 | 443 | Ingress HTTPS |

## 存储配置

### 数据持久化
```yaml
volumes:
  - ../../jenkins-data-github:/var/jenkins_home  # Jenkins 数据
  - /var/run/docker.sock:/var/run/docker.sock    # Docker Socket
  - ./kubeconfig:/var/jenkins_home/.kube          # Kubernetes 配置
  - /var/lib/docker                               # Kind 集群数据
```

## CI/CD 流水线

### Jenkinsfile 配置
- **文件位置**: `deployment/ci/Jenkinsfile.docker-only`
- **触发方式**: GitHub Webhook + 定时检查
- **构建环境**: Docker 容器

### 流水线阶段
1. **环境检查** - 验证 Docker 和网络
2. **代码检出** - 从 GitHub 拉取代码
3. **前端测试** - 运行单元测试
4. **前端构建** - 构建 React 应用
5. **镜像构建** - 构建 Docker 镜像
6. **镜像推送** - 推送到本地仓库
7. **Kubernetes 部署** - 部署到 Kind 集群
8. **部署验证** - 验证部署状态

### kubectl 配置
```bash
# Jenkins 容器内使用
kubectl --kubeconfig=/var/jenkins_home/.kube/config get nodes
```

## Kubernetes 资源

### 命名空间
- `sical` - 应用命名空间
- `sical-system` - 系统命名空间

### 应用部署
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sical-frontend
  namespace: sical
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sical-frontend
  template:
    spec:
      containers:
      - name: frontend
        image: localhost:5000/sical-frontend:latest
        ports:
        - containerPort: 80
```

## 故障排除

### 常见问题

#### 1. Kind 集群启动失败
```bash
# 检查容器状态
docker ps | grep kind

# 查看启动日志
docker logs kind-cluster

# 重新启动
docker-compose -f docker-compose-docker-only.yml restart kind-cluster
```

#### 2. Jenkins 无法连接 Kubernetes
```bash
# 检查 kubeconfig 文件
docker exec jenkins-github-base-tools ls -la /var/jenkins_home/.kube/

# 测试连接
docker exec jenkins-github-base-tools kubectl --kubeconfig=/var/jenkins_home/.kube/config get nodes

# 查看初始化日志
docker logs jenkins-github-base-tools
```

#### 3. 镜像推送失败
```bash
# 检查 Registry 状态
curl http://localhost:5000/v2/_catalog

# 检查网络连接
docker exec jenkins-github-base-tools ping registry
```

### 日志查看
```bash
# 查看所有服务日志
docker-compose -f docker-compose-docker-only.yml logs

# 查看特定服务日志
docker-compose -f docker-compose-docker-only.yml logs jenkins-github
docker-compose -f docker-compose-docker-only.yml logs kind-cluster
docker-compose -f docker-compose-docker-only.yml logs registry
```

### 健康检查
```bash
# 检查服务健康状态
docker-compose -f docker-compose-docker-only.yml ps

# 手动健康检查
curl -f http://localhost:8080/login  # Jenkins
curl -f http://localhost:5000/v2/    # Registry
curl -k https://localhost:6443/healthz  # Kind API
```

## 清理和重置

### 停止服务
```bash
docker-compose -f docker-compose-docker-only.yml down
```

### 清理数据
```bash
# 删除容器和网络
docker-compose -f docker-compose-docker-only.yml down -v

# 清理镜像
docker system prune -a

# 清理 Jenkins 数据（可选）
rm -rf ../../jenkins-data-github
```

### 完全重置
```bash
# 停止所有服务
docker-compose -f docker-compose-docker-only.yml down -v

# 删除相关镜像
docker rmi jenkins-github:base-tools base-tools:latest

# 重新构建和启动
./build-and-deploy.sh
```

## 安全注意事项

1. **Docker Socket 访问**: Jenkins 容器具有 Docker 完全访问权限
2. **网络隔离**: 使用专用 Docker 网络
3. **密钥管理**: 通过环境变量管理敏感信息
4. **端口暴露**: 仅暴露必要端口

## 性能优化

1. **资源限制**: 为容器设置适当的资源限制
2. **镜像缓存**: 利用 Docker 镜像层缓存
3. **并行构建**: 在 Jenkins 中启用并行构建
4. **存储优化**: 定期清理未使用的镜像和容器

## 监控和日志

### 推荐监控指标
- 容器资源使用率
- Jenkins 构建成功率
- Kubernetes 集群健康状态
- 镜像仓库存储使用量

### 日志管理
- 使用 Docker 日志驱动
- 配置日志轮转
- 集中化日志收集（可选）

## 扩展和定制

### 添加新服务
1. 在 `docker-compose-docker-only.yml` 中定义服务
2. 配置网络和依赖关系
3. 更新健康检查

### 自定义 Jenkins 插件
1. 编辑 `jenkins/plugins.txt`
2. 重新构建 Jenkins 镜像
3. 重启服务

### 扩展 Kubernetes 资源
1. 在 `k8s-resources/` 目录添加 YAML 文件
2. 更新 Jenkinsfile 部署脚本
3. 测试部署流程

---

**注意**: 本部署方案适用于开发和测试环境。生产环境部署需要额外的安全和高可用性配置。