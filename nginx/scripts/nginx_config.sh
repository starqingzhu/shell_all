#!/bin/bash

# Nginx公共配置文件
# 适配当前目录安装结构的配置

# ===========================================
# 动态路径配置
# ===========================================

# 获取脚本所在目录的父目录（项目根目录）
# 如果被source，使用BASH_SOURCE；否则使用$0
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
else
    SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
fi
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# ===========================================
# 基础路径配置
# ===========================================
# nginx主目录（项目根目录）
NGINX_HOME="$PROJECT_ROOT"

# nginx可执行文件路径
NGINX_BIN="${NGINX_HOME}/bin/nginx"

# nginx配置文件路径
NGINX_CONF="${NGINX_HOME}/conf/nginx.conf"

# nginx进程PID文件路径
NGINX_PID="${NGINX_HOME}/run/nginx.pid"

# ===========================================
# 日志文件路径
# ===========================================
# 错误日志文件路径
NGINX_ERROR_LOG="${NGINX_HOME}/logs/error.log"

# 访问日志文件路径
NGINX_ACCESS_LOG="${NGINX_HOME}/logs/access.log"

# ===========================================
# 功能函数
# ===========================================

# 检查nginx配置是否正确初始化
check_required_paths() {
    local errors=0
    
    if [ ! -d "$NGINX_HOME" ]; then
        echo "✗ Nginx主目录不存在: $NGINX_HOME"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "$NGINX_BIN" ]; then
        echo "✗ Nginx可执行文件不存在: $NGINX_BIN"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "$NGINX_CONF" ]; then
        echo "✗ Nginx配置文件不存在: $NGINX_CONF"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# 创建必要目录
create_directories() {
    local dirs=(
        "$NGINX_HOME/logs"
        "$NGINX_HOME/run"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "✓ 创建目录: $dir"
        fi
    done
}