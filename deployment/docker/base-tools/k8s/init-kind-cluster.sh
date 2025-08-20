#!/bin/bash
set -e

echo "=== 初始化Kind Kubernetes集群 ==="

# 启动systemd
/usr/local/bin/entrypoint /sbin/init &
SYSTEMD_PID=$!

# 等待systemd启动
echo "等待systemd启动..."
sleep 10

# 等待kubelet配置文件生成
echo "等待kubelet配置..."
while [ ! -f /var/lib/kubelet/config.yaml ]; do
    echo "等待kubelet配置文件生成..."
    sleep 5
done

# 启动kubelet服务
echo "启动kubelet服务..."
systemctl start kubelet

# 等待kubelet启动
echo "等待kubelet启动..."
sleep 15

# 等待API服务器启动
echo "等待Kubernetes API服务器启动..."
while ! curl -k https://localhost:6443/healthz >/dev/null 2>&1; do
    echo "等待API服务器响应..."
    sleep 10
done

echo "API服务器已启动"

# 生成kubeconfig文件
echo "生成kubeconfig文件..."
mkdir -p /shared/kubeconfig

# 复制admin kubeconfig
if [ -f /etc/kubernetes/admin.conf ]; then
    cp /etc/kubernetes/admin.conf /shared/kubeconfig/config
    # 修改server地址为容器名
    sed -i 's/server: https:\/\/.*:6443/server: https:\/\/kind-cluster:6443/g' /shared/kubeconfig/config
    echo "kubeconfig文件已生成: /shared/kubeconfig/config"
else
    echo "警告: admin.conf文件不存在"
fi

# 等待所有系统Pod启动
echo "等待系统Pod启动..."
kubectl --kubeconfig=/shared/kubeconfig/config wait --for=condition=Ready pods --all -n kube-system --timeout=300s || true

echo "=== Kind集群初始化完成 ==="

# 保持容器运行
wait $SYSTEMD_PID