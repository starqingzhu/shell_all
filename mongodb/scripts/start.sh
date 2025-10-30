#!/bin/bash

# MongoDB 启动脚本

# 获取脚本目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_DIR/bin"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
CONF_DIR="$PROJECT_DIR/conf"

# 创建必要的目录
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# MongoDB 配置文件路径（使用conf目录下的官方配置文件）
CONFIG_FILE="$CONF_DIR/mongod.conf"
PID_FILE="$DATA_DIR/mongod.pid"
LOG_FILE="$LOG_DIR/mongod.log"

# 检查 MongoDB 是否已安装
if [ ! -f "$BIN_DIR/mongod" ]; then
    echo "Error: MongoDB not found in $BIN_DIR"
    echo "Please run ../install.sh first"
    exit 1
fi

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    echo "Please run the configuration script first:"
    echo "  ./config.sh"
    echo "Or run ../install.sh to download the default configuration file"
    exit 1
fi

# 检查配置文件是否已经为本地路径配置过
if grep -q "/var/lib/mongodb" "$CONFIG_FILE"; then
    echo "Warning: Configuration file contains default paths"
    echo "Please run the configuration script to update paths:"
    echo "  ./config.sh"
    exit 1
fi

# 检查 MongoDB 是否已经在运行
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "MongoDB is already running (PID: $PID)"
        exit 1
    else
        echo "Removing stale PID file"
        rm -f "$PID_FILE"
    fi
fi

# 启动 MongoDB
echo "Starting MongoDB..."
"$BIN_DIR/mongod" --config "$CONFIG_FILE"

# 检查启动是否成功
sleep 2
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "MongoDB started successfully (PID: $PID)"
        echo "Config file: $CONFIG_FILE"
        echo "Data directory: $DATA_DIR"
        echo "Log file: $LOG_FILE"
    else
        echo "Failed to start MongoDB"
        exit 1
    fi
else
    echo "Failed to start MongoDB - no PID file created"
    exit 1
fi