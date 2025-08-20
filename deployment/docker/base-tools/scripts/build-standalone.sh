#!/bin/bash
set -e

echo "=== 构建独立的 base-tools 镜像 ==="

# 检查必要文件
echo "检查必要文件..."
if [ ! -f "../Dockerfile" ]; then
    echo "❌ 错误: Dockerfile 不存在"
    exit 1
fi

if [ ! -f "../kubectl" ]; then
    echo "❌ 错误: kubectl 文件不存在"
    exit 1
fi

if [ ! -f "../../../mirrors.json" ]; then
    echo "❌ 错误: mirrors.json 文件不存在"
    exit 1
fi

echo "✅ 所有必要文件检查完成"

# 切换到deployment目录进行构建
cd ../../../

# 构建base-tools镜像
echo "\n=== 构建 base-tools 镜像 ==="
docker build -f docker/base-tools/Dockerfile -t base-tools:latest .

if [ $? -eq 0 ]; then
    echo "✅ base-tools 镜像构建成功"
else
    echo "❌ base-tools 镜像构建失败"
    exit 1
fi

# 显示镜像信息
echo "\n=== 镜像信息 ==="
docker images base-tools:latest

# 验证工具版本
echo "\n=== 验证工具版本 ==="
docker run --rm base-tools:latest kubectl version --client
docker run --rm base-tools:latest helm version
docker run --rm base-tools:latest kind version
docker run --rm base-tools:latest kustomize version
docker run --rm base-tools:latest docker-compose version

echo "\n=== 构建完成 ==="
echo "使用以下命令启动独立的base-tools服务:"
echo "docker-compose -f docker/base-tools/docker-compose-standalone.yml up -d"
echo ""
echo "进入base-tools容器:"
echo "docker exec -it base-tools-standalone bash"