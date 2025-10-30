#!/bin/bash

# MongoDB 停止脚本

# 获取脚本目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_DIR/bin"
DATA_DIR="$PROJECT_DIR/data"

# MongoDB PID 文件路径
PID_FILE="$DATA_DIR/mongod.pid"

# 检查 MongoDB 是否在运行
if [ ! -f "$PID_FILE" ]; then
    echo "MongoDB is not running (no PID file found)"
    exit 1
fi

PID=$(cat "$PID_FILE")

# 检查进程是否存在
if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "MongoDB is not running (process $PID not found)"
    rm -f "$PID_FILE"
    exit 1
fi

echo "Stopping MongoDB (PID: $PID)..."

# 尝试优雅关闭
if [ -f "$BIN_DIR/mongod" ]; then
    # 使用 MongoDB 自带的关闭命令
    "$BIN_DIR/mongod" --shutdown --dbpath "$DATA_DIR"
    
    # 等待进程关闭
    TIMEOUT=30
    COUNT=0
    while ps -p "$PID" > /dev/null 2>&1 && [ $COUNT -lt $TIMEOUT ]; do
        sleep 1
        COUNT=$((COUNT + 1))
        echo -n "."
    done
    echo
    
    # 检查是否成功关闭
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Warning: MongoDB did not shut down gracefully, forcing termination..."
        kill -TERM "$PID"
        sleep 3
        
        # 如果还没关闭，强制杀死
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Force killing MongoDB process..."
            kill -KILL "$PID"
        fi
    fi
else
    # 如果没有 mongod 命令，直接杀死进程
    echo "Warning: mongod command not found, killing process directly..."
    kill -TERM "$PID"
    sleep 3
    
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Force killing MongoDB process..."
        kill -KILL "$PID"
    fi
fi

# 清理 PID 文件
rm -f "$PID_FILE"

# 最终检查
if ps -p "$PID" > /dev/null 2>&1; then
    echo "Failed to stop MongoDB (PID: $PID)"
    exit 1
else
    echo "MongoDB stopped successfully"
fi