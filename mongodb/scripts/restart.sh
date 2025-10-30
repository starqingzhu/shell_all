#!/bin/bash

# MongoDB 重启脚本

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restarting MongoDB..."

# 先停止 MongoDB
echo "Step 1: Stopping MongoDB..."
"$SCRIPT_DIR/stop.sh"

# 检查停止是否成功
if [ $? -ne 0 ]; then
    echo "Failed to stop MongoDB, aborting restart"
    exit 1
fi

# 等待一下确保完全停止
sleep 2

# 再启动 MongoDB
echo "Step 2: Starting MongoDB..."
"$SCRIPT_DIR/start.sh"

# 检查启动是否成功
if [ $? -eq 0 ]; then
    echo "MongoDB restarted successfully"
else
    echo "Failed to restart MongoDB"
    exit 1
fi