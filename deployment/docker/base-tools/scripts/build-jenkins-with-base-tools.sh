#!/bin/bash

# 构建Jenkins镜像基于base-tools
# 这个脚本会先构建base-tools镜像，然后基于它构建Jenkins镜像

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker是否运行
if ! docker info >/dev/null 2>&1; then
    log_error "Docker未运行，请启动Docker后重试"
    exit 1
fi

# 设置工作目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

log_info "项目根目录: ${PROJECT_ROOT}"

# 检查必要文件
required_files=(
    "deployment/docker/Dockerfile.base-tools"
    "deployment/docker/jenkins/Dockerfile.base-tools"
    "deployment/mirrors.json"
    "deployment/docker/read-mirrors.sh"
    "deployment/docker/kubectl"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        log_error "缺少必要文件: $file"
        exit 1
    fi
done

# 读取镜像源配置
DOCKER_HUB_PROXY=$(jq -r '.docker.hub_proxy // "docker.m.daocloud.io"' deployment/mirrors.json)
log_info "使用Docker Hub代理: ${DOCKER_HUB_PROXY}"

# 构建base-tools镜像
log_info "开始构建base-tools镜像..."
docker build \
    --build-arg DOCKER_HUB_PROXY="${DOCKER_HUB_PROXY}" \
    -f deployment/docker/Dockerfile.base-tools \
    -t base-tools:latest \
    .

if [[ $? -eq 0 ]]; then
    log_info "base-tools镜像构建成功"
else
    log_error "base-tools镜像构建失败"
    exit 1
fi

# 构建Jenkins镜像（基于base-tools）
log_info "开始构建Jenkins镜像（基于base-tools）..."
docker build \
    --build-arg DOCKER_HUB_PROXY="${DOCKER_HUB_PROXY}" \
    --build-arg BASE_TOOLS_IMAGE="base-tools:latest" \
    -f deployment/docker/jenkins/Dockerfile.base-tools \
    -t jenkins-github:base-tools \
    .

if [[ $? -eq 0 ]]; then
    log_info "Jenkins镜像构建成功"
else
    log_error "Jenkins镜像构建失败"
    exit 1
fi

# 显示镜像信息
log_info "构建完成的镜像:"
docker images | grep -E "(base-tools|jenkins-github)"

# 验证工具安装
log_info "验证Jenkins镜像中的工具..."
docker run --rm jenkins-github:base-tools bash -c "
    echo '=== 验证工具版本 ==='
    kubectl version --client
    echo '---'
    helm version
    echo '---'
    kind version
    echo '---'
    docker --version
    echo '---'
    node --version
    echo '---'
    npm --version
"

log_info "Jenkins镜像构建并验证完成！"
log_info "可以使用以下命令启动Jenkins容器:"
echo "docker run -d --name jenkins-github-base-tools -p 8080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock jenkins-github:base-tools"