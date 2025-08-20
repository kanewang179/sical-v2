# Sical Deploy镜像 - 包含Jenkins和常用的Kubernetes工具
# 用于减少重复下载，提高构建效率
FROM jenkins/jenkins:lts-alpine

# 切换到root用户进行系统配置
USER root

# 配置Alpine国内镜像源
RUN echo 'https://mirrors.aliyun.com/alpine/v3.18/main' > /etc/apk/repositories && \
    echo 'https://mirrors.aliyun.com/alpine/v3.18/community' >> /etc/apk/repositories

# 安装基础工具
RUN apk add --no-cache \
    curl \
    wget \
    bash \
    git \
    jq \
    yq \
    unzip \
    tar \
    gzip \
    python3 \
    && rm -rf /var/cache/apk/*

# 设置镜像源环境变量（硬编码）
ENV ALPINE_MIRROR=https://mirrors.aliyun.com/alpine \
    DOCKER_MIRROR=https://registry.cn-hangzhou.aliyuncs.com \
    JENKINS_UPDATE_CENTER=https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates \
    GITHUB_MIRROR=https://ghproxy.com \
    PIP_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple \
    NPM_MIRROR=https://registry.npmmirror.com \
    MAVEN_MIRROR=https://maven.aliyun.com/repository/public \
    GRADLE_MIRROR=https://maven.aliyun.com/repository/gradle-plugin

# 复制本地kubectl文件
COPY kubectl /tmp/kubectl

# 安装 kubectl (使用本地文件)
RUN echo "Installing tools for linux/amd64 architecture" && \
    echo "使用本地 kubectl 文件..." && \
    cp /tmp/kubectl /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# 安装 Helm
RUN echo "下载 helm..." && \
    curl -fsSL "https://get.helm.sh/helm-v3.17.4-linux-amd64.tar.gz" | tar -xz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64

# 安装 kustomize (使用DaoCloud镜像源)
RUN echo "下载 kustomize..." && \
    curl -fsSL "https://files.m.daocloud.io/github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.2.1/kustomize_v5.2.1_linux_amd64.tar.gz" | tar -xz && \
    mv kustomize /usr/local/bin/

# 安装 kind (使用DaoCloud镜像源)
RUN echo "下载 kind..." && \
    curl -Lo ./kind "https://files.m.daocloud.io/github.com/kubernetes-sigs/kind/releases/download/v0.20.0/kind-linux-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin/kind

# 安装 Docker 客户端
RUN echo "安装 Docker 客户端..." && \
    apk add --no-cache docker-cli

# 安装 docker-compose (使用DaoCloud镜像源)
RUN echo "下载 docker-compose..." && \
    curl -L "https://files.m.daocloud.io/github.com/docker/compose/releases/download/v2.21.0/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# 复制Jenkins配置文件
COPY jenkins/init.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY jenkins/jenkins-plugin-mirror.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt

# 复制Jenkins启动脚本
COPY base-tools/jenkins/jenkins-entrypoint.sh /usr/local/bin/jenkins-entrypoint.sh
COPY base-tools/jenkins/jenkins-init-kubectl.sh /usr/local/bin/jenkins-init-kubectl.sh
RUN chmod +x /usr/local/bin/jenkins-entrypoint.sh /usr/local/bin/jenkins-init-kubectl.sh

# 安装Jenkins插件
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# 验证工具安装
RUN kubectl version --client && \
    helm version && \
    kustomize version && \
    kind version

# 设置工作目录
WORKDIR /var/jenkins_home

# 暴露Jenkins端口
EXPOSE 8080 50000

# 切换到jenkins用户
USER jenkins

# 启动命令
CMD ["/usr/local/bin/jenkins-entrypoint.sh"]