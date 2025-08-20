#!/bin/bash
set -e

echo "=== 启动Jenkins容器 ==="

# 在后台运行kubectl初始化脚本
echo "启动kubectl初始化脚本..."
/usr/local/bin/jenkins-init-kubectl.sh &

# 启动Jenkins
echo "启动Jenkins服务..."
exec /usr/local/bin/jenkins.sh "$@"