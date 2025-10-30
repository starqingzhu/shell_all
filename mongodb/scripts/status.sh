#!/bin/bash

# MongoDB 状态检查脚本

# 获取脚本目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_DIR/bin"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
CONF_DIR="$PROJECT_DIR/conf"

# MongoDB 相关文件路径
PID_FILE="$DATA_DIR/mongod.pid"
LOG_FILE="$LOG_DIR/mongod.log"
CONFIG_FILE="$CONF_DIR/mongod.conf"

echo "=========================================="
echo "MongoDB Status Check"
echo "=========================================="

# 检查 MongoDB 是否已安装
if [ -f "$BIN_DIR/mongod" ]; then
    MONGOD_VERSION=$("$BIN_DIR/mongod" --version | head -n 1)
    echo "MongoDB Binary: $BIN_DIR/mongod"
    echo "Version: $MONGOD_VERSION"
else
    echo "MongoDB Binary: NOT FOUND"
    echo "Please run install.sh first"
    echo "=========================================="
    exit 1
fi

# 检查配置文件
if [ -f "$CONFIG_FILE" ]; then
    echo "Config File: $CONFIG_FILE (EXISTS)"
else
    echo "Config File: $CONFIG_FILE (NOT FOUND)"
fi

# 检查数据目录
if [ -d "$DATA_DIR" ]; then
    DATA_SIZE=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)
    echo "Data Directory: $DATA_DIR (EXISTS, Size: $DATA_SIZE)"
else
    echo "Data Directory: $DATA_DIR (NOT FOUND)"
fi

# 检查日志文件
if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(du -sh "$LOG_FILE" 2>/dev/null | cut -f1)
    echo "Log File: $LOG_FILE (EXISTS, Size: $LOG_SIZE)"
else
    echo "Log File: $LOG_FILE (NOT FOUND)"
fi

echo "=========================================="

# 检查进程状态
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    echo "PID File: $PID_FILE (EXISTS)"
    echo "Process ID: $PID"
    
    if ps -p "$PID" > /dev/null 2>&1; then
        # 获取进程详细信息
        PROCESS_INFO=$(ps -p "$PID" -o pid,ppid,user,cpu,mem,etime,cmd --no-headers)
        echo "Process Status: RUNNING"
        echo "Process Info: $PROCESS_INFO"
        
        # 检查端口是否在监听
        if command -v netstat >/dev/null 2>&1; then
            PORT_INFO=$(netstat -tlnp 2>/dev/null | grep ":27017 " | head -n 1)
            if [ -n "$PORT_INFO" ]; then
                echo "Port Status: 27017 LISTENING"
                echo "Port Info: $PORT_INFO"
            else
                echo "Port Status: 27017 NOT LISTENING"
            fi
        elif command -v ss >/dev/null 2>&1; then
            PORT_INFO=$(ss -tlnp | grep ":27017 " | head -n 1)
            if [ -n "$PORT_INFO" ]; then
                echo "Port Status: 27017 LISTENING"
                echo "Port Info: $PORT_INFO"
            else
                echo "Port Status: 27017 NOT LISTENING"
            fi
        fi
        
        # 尝试连接测试
        MONGO_CLIENT=""
        if [ -f "$BIN_DIR/mongosh" ]; then
            MONGO_CLIENT="$BIN_DIR/mongosh"
        elif [ -f "$BIN_DIR/mongo" ]; then
            MONGO_CLIENT="$BIN_DIR/mongo"
        fi
        
        if [ -n "$MONGO_CLIENT" ]; then
            echo "Connection Test:"
            if [[ "$MONGO_CLIENT" == *"mongosh"* ]]; then
                # 使用 mongosh
                CONNECT_TEST=$("$MONGO_CLIENT" --eval "print('Connection successful')" --quiet 2>/dev/null)
            else
                # 使用 mongo
                CONNECT_TEST=$("$MONGO_CLIENT" --eval "print('Connection successful')" --quiet 2>/dev/null)
            fi
            
            if [ $? -eq 0 ]; then
                echo "  MongoDB Connection: SUCCESS"
                echo "  Response: $CONNECT_TEST"
                echo "  Client: $(basename "$MONGO_CLIENT")"
            else
                echo "  MongoDB Connection: FAILED"
            fi
        else
            echo "Connection Test: SKIPPED (no client found)"
        fi
        
    else
        echo "Process Status: NOT RUNNING (stale PID file)"
        echo "Note: PID file exists but process $PID is not running"
    fi
else
    echo "PID File: NOT FOUND"
    echo "Process Status: NOT RUNNING"
fi

echo "=========================================="

# 显示最近的日志（如果存在）
if [ -f "$LOG_FILE" ]; then
    echo "Recent Log Entries (last 5 lines):"
    tail -n 5 "$LOG_FILE"
    echo "=========================================="
fi

# 总结状态
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Overall Status: RUNNING"
        exit 0
    else
        echo "Overall Status: STOPPED (stale PID file)"
        exit 1
    fi
else
    echo "Overall Status: STOPPED"
    exit 1
fi