#!/bin/bash

# Sical项目构建脚本 - 分离式架构
# 支持分别构建base-tools和jenkins镜像

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker是否运行
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker未运行，请启动Docker后重试"
        exit 1
    fi
    log_info "Docker运行正常"
}

# 构建base-tools镜像
build_base_tools() {
    log_info "开始构建base-tools镜像..."
    
    cd base-tools
    
    # 检查kubectl文件是否存在
    if [ ! -f "kubectl" ]; then
        log_error "kubectl文件不存在，请先下载kubectl二进制文件"
        exit 1
    fi
    
    docker build -t sical-base-tools:latest .
    
    if [ $? -eq 0 ]; then
        log_success "base-tools镜像构建成功"
        
        # 验证工具
        log_info "验证base-tools中的工具..."
        docker run --rm sical-base-tools:latest kubectl version --client
        docker run --rm sical-base-tools:latest helm version
        docker run --rm sical-base-tools:latest kustomize version
        docker run --rm sical-base-tools:latest kind version
        
        log_success "base-tools工具验证完成"
    else
        log_error "base-tools镜像构建失败"
        exit 1
    fi
    
    cd ..
}

# 构建jenkins镜像
build_jenkins() {
    log_info "开始构建jenkins镜像..."
    
    cd jenkins
    
    # 检查必要的配置文件
    required_files=("init.groovy" "jenkins-plugin-mirror.groovy" "plugins.txt" "jenkins-entrypoint.sh" "jenkins-init-kubectl.sh")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Jenkins配置文件 $file 不存在"
            exit 1
        fi
    done
    
    docker build -t sical-jenkins:latest .
    
    if [ $? -eq 0 ]; then
        log_success "jenkins镜像构建成功"
    else
        log_error "jenkins镜像构建失败"
        exit 1
    fi
    
    cd ..
}

# 显示帮助信息
show_help() {
    echo "Sical项目构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  base-tools    只构建base-tools镜像"
    echo "  jenkins       只构建jenkins镜像（需要先构建base-tools）"
    echo "  all           构建所有镜像（默认）"
    echo "  clean         清理所有镜像"
    echo "  help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              # 构建所有镜像"
    echo "  $0 base-tools   # 只构建base-tools镜像"
    echo "  $0 jenkins      # 只构建jenkins镜像"
    echo "  $0 clean        # 清理所有镜像"
}

# 清理镜像
clean_images() {
    log_info "清理Sical相关镜像..."
    
    # 停止并删除容器
    docker-compose down 2>/dev/null || true
    
    # 删除镜像
    docker rmi sical-jenkins:latest 2>/dev/null || true
    docker rmi sical-base-tools:latest 2>/dev/null || true
    
    # 清理悬空镜像
    docker image prune -f
    
    log_success "镜像清理完成"
}

# 主函数
main() {
    local action=${1:-all}
    
    case $action in
        "base-tools")
            check_docker
            build_base_tools
            ;;
        "jenkins")
            check_docker
            # 检查base-tools镜像是否存在
            if ! docker image inspect sical-base-tools:latest >/dev/null 2>&1; then
                log_warning "base-tools镜像不存在，先构建base-tools镜像"
                build_base_tools
            fi
            build_jenkins
            ;;
        "all")
            check_docker
            build_base_tools
            build_jenkins
            log_success "所有镜像构建完成"
            ;;
        "clean")
            clean_images
            ;;
        "help")
            show_help
            ;;
        *)
            log_error "未知选项: $action"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"