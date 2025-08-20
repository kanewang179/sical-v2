#!/bin/bash
set -e

echo "=== 配置Jenkins kubectl连接到Kind集群 ==="

# 等待kubeconfig文件生成
echo "等待kubeconfig文件..."
while [ ! -f /var/jenkins_home/.kube/config ]; do
    echo "等待kubeconfig文件生成..."
    sleep 10
done

echo "kubeconfig文件已找到"

# 验证kubectl连接
echo "验证kubectl连接..."
for i in {1..30}; do
    if kubectl --kubeconfig=/var/jenkins_home/.kube/config get nodes >/dev/null 2>&1; then
        echo "kubectl连接成功"
        kubectl --kubeconfig=/var/jenkins_home/.kube/config get nodes
        break
    else
        echo "尝试连接Kind集群... ($i/30)"
        sleep 10
    fi
done

# 配置Git全局设置（解决HTTP2问题）
echo "配置Git设置..."
git config --global http.version HTTP/1.1
git config --global http.https://github.com.version HTTP/1.1
git config --global http.postBuffer 524288000
git config --global http.maxRequestBuffer 100M
git config --global core.compression 0

echo "=== Jenkins kubectl配置完成 ==="