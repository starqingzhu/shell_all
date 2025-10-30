#!/bin/bash

# Nginx停止脚本 - 简化版
# 专注于停止功能

# 获取脚本所在目录
SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)

# 加载公共配置
source "${SCRIPT_PATH}/nginx_config.sh"

echo "=== 停止 Nginx ==="

# 检查PID文件
if [ ! -f "$NGINX_PID" ] || [ ! -s "$NGINX_PID" ]; then
    echo "✓ Nginx未运行"
    exit 0
fi

PID=$(cat $NGINX_PID)

# 检查进程是否存在
if ! ps -p $PID > /dev/null 2>&1; then
    echo "✓ Nginx未运行"
    rm -f $NGINX_PID
    exit 0
fi

echo "正在停止nginx (PID: $PID)..."

# 优雅停止
kill -QUIT $PID 2>/dev/null

# 等待停止
for i in {1..10}; do
    if ! ps -p $PID > /dev/null 2>&1; then
        echo "✓ Nginx已停止"
        rm -f $NGINX_PID
        exit 0
    fi
    sleep 1
done

# 强制停止
echo "优雅停止超时，强制停止..."
kill -TERM $PID 2>/dev/null

# 等待强制停止
for i in {1..5}; do
    if ! ps -p $PID > /dev/null 2>&1; then
        echo "✓ Nginx已强制停止"
        rm -f $NGINX_PID
        exit 0
    fi
    sleep 1
done

# 最后手段
kill -9 $PID 2>/dev/null
sleep 1

if ! ps -p $PID > /dev/null 2>&1; then
    echo "✓ Nginx已终止"
    rm -f $NGINX_PID
else
    echo "✗ 无法停止nginx进程"
    exit 1
fi