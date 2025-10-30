#!/bin/bash

# MongoDB 连接脚本

# 获取脚本目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_DIR/bin"
DATA_DIR="$PROJECT_DIR/data"

# MongoDB PID 文件路径
PID_FILE="$DATA_DIR/mongod.pid"

# 检查 MongoDB 客户端是否存在（支持新旧版本）
MONGO_CLIENT=""

# 调试信息 - 可以临时启用来检查路径
# echo "Debug: SCRIPT_DIR = $SCRIPT_DIR"
# echo "Debug: PROJECT_DIR = $PROJECT_DIR" 
# echo "Debug: BIN_DIR = $BIN_DIR"

if [ -f "$BIN_DIR/mongosh" ]; then
    MONGO_CLIENT="$BIN_DIR/mongosh"
    echo "Found MongoDB Shell (mongosh)"
elif [ -f "$BIN_DIR/mongo" ]; then
    MONGO_CLIENT="$BIN_DIR/mongo"
    echo "Found MongoDB Shell (mongo)"
else
    echo "Error: MongoDB client not found in $BIN_DIR"
    echo "Looking for: mongosh or mongo"
    echo "Available files in $BIN_DIR:"
    ls -la "$BIN_DIR/" 2>/dev/null || echo "Directory does not exist"
    echo ""
    echo "Please install MongoDB client first:"
    echo "  ../install_client.sh"
    echo "Or run ../install.sh to install MongoDB server first"
    exit 1
fi

# 检查 MongoDB 服务是否在运行
if [ ! -f "$PID_FILE" ]; then
    echo "Error: MongoDB is not running"
    echo "Please start MongoDB first: ./start.sh"
    exit 1
fi

PID=$(cat "$PID_FILE")
if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "Error: MongoDB is not running (process $PID not found)"
    echo "Please start MongoDB first: ./start.sh"
    exit 1
fi

echo "Connecting to MongoDB..."
echo "MongoDB PID: $PID"
echo "Client: $MONGO_CLIENT"
echo "Use 'exit' or Ctrl+C to disconnect"
echo "=========================================="

# 连接到 MongoDB（根据客户端类型使用不同参数）
if [[ "$MONGO_CLIENT" == *"mongosh"* ]]; then
    # 使用 mongosh（新版本）
    "$MONGO_CLIENT" --host 127.0.0.1 --port 27017
else
    # 使用 mongo（旧版本）
    "$MONGO_CLIENT" --host 127.0.0.1 --port 27017
fi