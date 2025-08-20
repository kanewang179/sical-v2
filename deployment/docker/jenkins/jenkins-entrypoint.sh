#!/bin/bash
set -e

echo "=== 启动Jenkins容器 ==="

# 在后台运行kubectl初始化脚本
echo "启动kubectl初始化脚本..."
/usr/local/bin/jenkins-init-kubectl.sh &

# 启动Jenkins
echo "启动Jenkins服务..."
# 设置Java参数强制IPv4绑定
export JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false -Djava.awt.headless=true"
exec /usr/local/bin/jenkins.sh "$@"