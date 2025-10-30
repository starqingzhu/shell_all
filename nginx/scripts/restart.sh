#!/bin/bash

# Nginx重启脚本 - 简化版
# 专注于重启功能

# 获取脚本所在目录
SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)

echo "=== 重启 Nginx ==="

# 检查脚本文件存在
if [ ! -f "${SCRIPT_PATH}/stop.sh" ] || [ ! -f "${SCRIPT_PATH}/start.sh" ]; then
    echo "✗ 缺少stop.sh或start.sh脚本"
    exit 1
fi

# 停止nginx
echo "停止nginx..."
bash "${SCRIPT_PATH}/stop.sh"
if [ $? -ne 0 ]; then
    echo "✗ 停止失败"
    exit 1
fi

# 等待确保完全停止
sleep 2

# 启动nginx
echo "启动nginx..."
bash "${SCRIPT_PATH}/start.sh"
if [ $? -eq 0 ]; then
    echo "✓ Nginx重启成功"
else
    echo "✗ 启动失败"
    exit 1
fi