#!/bin/bash
set -e

echo "=== 构建 sical-deploy 镜像 ==="

# 检查必要文件
echo "检查必要文件..."
if [ ! -f "./Dockerfile" ]; then
    echo "❌ 错误: base-tools Dockerfile 不存在"
    exit 1
fi

if [ ! -f "../kubectl" ]; then
    echo "❌ 错误: kubectl 文件不存在"
    exit 1
fi

# mirrors.json 已改为硬编码，无需检查

echo "✅ 所有必要文件检查完成"

# 切换到deployment/docker目录进行构建
cd ../

# 构建sical-deploy镜像
echo "\n=== 构建 sical-deploy 镜像 ==="
docker build -f base-tools/Dockerfile -t sical-deploy:latest .

if [ $? -eq 0 ]; then
    echo "✅ sical-deploy 镜像构建成功"
else
    echo "❌ sical-deploy 镜像构建失败"
    exit 1
fi

echo "\n=== 镜像构建完成 ==="
echo "可用镜像:"
docker images | grep sical-deploy

echo "\n=== 验证工具版本 ==="
echo "验证 kubectl 版本:"
docker run --rm sical-deploy:latest kubectl version --client

echo "\n验证 Kustomize 版本:"
docker run --rm sical-deploy:latest kustomize version

echo "\n验证 Helm 版本:"
docker run --rm sical-deploy:latest helm version

echo "\n验证 kind 版本:"
docker run --rm sical-deploy:latest kind version

echo "\n=== 构建完成 ==="
echo "可以使用以下命令启动服务:"
echo "docker-compose -f config/docker-compose.yml up -d"