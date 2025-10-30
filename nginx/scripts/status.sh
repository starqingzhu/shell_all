#!/bin/bash

# Nginx状态检查脚本 - 简化版
# 专注于状态检查功能

# 获取脚本所在目录和nginx路径
SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
NGINX_BIN="${SCRIPT_PATH}/../bin/nginx"
NGINX_PID="${SCRIPT_PATH}/../run/nginx.pid"

echo "=== Nginx 状态 ==="

# 检查nginx可执行文件
if [ ! -f "$NGINX_BIN" ]; then
    echo "✗ nginx未安装: $NGINX_BIN"
    exit 1
fi

# 检查PID文件和进程
if [ -f "$NGINX_PID" ] && [ -s "$NGINX_PID" ]; then
    PID=$(cat "$NGINX_PID")
    if ps -p $PID > /dev/null 2>&1; then
        echo "✓ nginx正在运行 (PID: $PID)"
        
        # 检查端口监听
        if command -v netstat >/dev/null 2>&1; then
            PORTS=$(netstat -tlnp 2>/dev/null | grep $PID | awk '{print $4}' | cut -d: -f2 | sort -n | uniq | tr '\n' ' ')
            if [ -n "$PORTS" ]; then
                echo "✓ 监听端口: $PORTS"
            fi
        fi
        exit 0
    else
        echo "✗ PID文件存在但进程不存在"
        rm -f "$NGINX_PID"
        exit 1
    fi
else
    echo "✗ nginx未运行"
    exit 1
fi