#!/bin/bash
# Redis 状态检查脚本

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(dirname "$SCRIPT_DIR")
REDIS_CLI="$BASE_DIR/bin/redis-cli"
PID_FILE="$BASE_DIR/data/redis.pid"

echo "检查 Redis 状态..."

# 检查PID文件
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "✓ Redis 进程运行中 (PID: $PID)"
        
        # 检查Redis是否响应
        if "$REDIS_CLI" ping >/dev/null 2>&1; then
            echo "✓ Redis 服务响应正常"
            echo ""
            echo "=== Redis 信息 ==="
            "$REDIS_CLI" INFO server | grep -E "redis_version|process_id|tcp_port|uptime"
            echo ""
            echo "=== 内存使用 ==="
            "$REDIS_CLI" INFO memory | grep -E "used_memory_human|used_memory_peak_human"
            echo ""
            echo "=== 连接数 ==="
            "$REDIS_CLI" INFO clients | grep "connected_clients"
        else
            echo "✗ Redis 进程存在但服务无响应"
            exit 1
        fi
    else
        echo "✗ PID文件存在但进程不存在"
        rm -f "$PID_FILE"
        exit 1
    fi
else
    echo "✗ Redis 未运行 (无PID文件)"
    exit 1
fi