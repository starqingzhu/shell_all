#!/bin/bash
# Redis 重启脚本

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "重启 Redis 服务器..."
echo "停止 Redis..."
"$SCRIPT_DIR/stop.sh"

echo "等待进程完全停止..."
sleep 3

echo "启动 Redis..."
"$SCRIPT_DIR/start.sh"