#!/bin/bash
# Redis 停止脚本

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(dirname "$SCRIPT_DIR")
REDIS_CLI="$BASE_DIR/bin/redis-cli"
PID_FILE="$BASE_DIR/data/redis.pid"

echo "停止 Redis 服务器..."

# 首先尝试通过 redis-cli 优雅关闭
if command -v "$REDIS_CLI" >/dev/null 2>&1; then
    "$REDIS_CLI" SHUTDOWN NOSAVE 2>/dev/null && echo "✓ Redis 优雅关闭成功"
else
    echo "⚠️  redis-cli 不可用，尝试通过PID关闭"
fi

# 检查PID文件
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "强制停止 Redis 进程 (PID: $PID)"
        kill "$PID"
        sleep 2
        
        # 如果还在运行，强制杀死
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "强制杀死 Redis 进程"
            kill -9 "$PID"
        fi
    fi
    rm -f "$PID_FILE"
    echo "✓ Redis 已停止"
else
    echo "未找到 PID 文件，Redis 可能未运行"
fi