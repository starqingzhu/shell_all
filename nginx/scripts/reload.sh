#!/bin/bash

# Nginx重载配置脚本 - 简化版
# 专注于配置重载功能

# 获取脚本所在目录和nginx路径
SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)
NGINX_BIN="${SCRIPT_PATH}/../bin/nginx"
NGINX_CONF="${SCRIPT_PATH}/../conf/nginx.conf"
NGINX_PID="${SCRIPT_PATH}/../run/nginx.pid"

echo "=== 重载 Nginx 配置 ==="

# 检查nginx是否安装
if [ ! -f "$NGINX_BIN" ]; then
    echo "✗ nginx未安装: $NGINX_BIN"
    exit 1
fi

# 检查配置文件
if [ ! -f "$NGINX_CONF" ]; then
    echo "✗ 配置文件不存在: $NGINX_CONF"
    exit 1
fi

# 测试配置文件语法
echo "测试配置文件语法..."
if ! "$NGINX_BIN" -t -c "$NGINX_CONF" >/dev/null 2>&1; then
    echo "✗ 配置文件语法错误"
    "$NGINX_BIN" -t -c "$NGINX_CONF"
    exit 1
fi

# 检查nginx是否运行
if [ ! -f "$NGINX_PID" ] || [ ! -s "$NGINX_PID" ]; then
    echo "✗ nginx未运行，无法重载配置"
    exit 1
fi

PID=$(cat "$NGINX_PID")
if ! ps -p $PID > /dev/null 2>&1; then
    echo "✗ nginx进程不存在"
    rm -f "$NGINX_PID"
    exit 1
fi

# 重载配置
echo "重载配置文件..."
if "$NGINX_BIN" -s reload -c "$NGINX_CONF"; then
    echo "✓ 配置重载成功"
else
    echo "✗ 配置重载失败"
    exit 1
fi