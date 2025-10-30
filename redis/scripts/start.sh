#!/bin/bash
# Redis 启动脚本

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(dirname "$SCRIPT_DIR")
REDIS_SERVER="$BASE_DIR/bin/redis-server"
REDIS_CONF="$BASE_DIR/conf/redis.conf"
PID_FILE="$BASE_DIR/data/redis.pid"
LOG_FILE="$BASE_DIR/data/redis.log"

# 检查是否已经运行
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Redis 已经在运行中 (PID: $PID)"
        exit 1
    else
        echo "删除过期的PID文件"
        rm -f "$PID_FILE"
    fi
fi

# 检查配置文件是否存在
if [ ! -f "$REDIS_CONF" ]; then
    echo "✗ Redis 配置文件不存在: $REDIS_CONF"
    echo "请先运行 install.sh 安装 Redis 并生成配置文件"
    exit 1
fi

echo "启动 Redis 服务器..."
"$REDIS_SERVER" "$REDIS_CONF"

# 等待启动
sleep 2

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    echo "✓ Redis 启动成功 (PID: $PID)"
    echo "配置文件: $REDIS_CONF"
    echo "日志文件: $LOG_FILE"
else
    echo "✗ Redis 启动失败，请检查日志: $LOG_FILE"
    exit 1
fi