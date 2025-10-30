#!/bin/bash

# MongoDB 配置脚本 - 配置 mongod.conf 文件

# 获取脚本目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONF_DIR="$PROJECT_DIR/conf"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"

# 配置文件路径
CONFIG_FILE="$CONF_DIR/mongod.conf"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_CONFIG="$CONF_DIR/mongod.conf.bak.$TIMESTAMP"

echo "=========================================="
echo "MongoDB Configuration Setup"
echo "=========================================="

# 创建必要的目录
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$CONF_DIR"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    echo "Please run ../install.sh first to download the configuration file"
    exit 1
fi

# 备份原始配置文件（每次都创建新备份）
echo "Creating backup of current configuration..."
cp "$CONFIG_FILE" "$BACKUP_CONFIG"
echo "Backup created: $BACKUP_CONFIG"

echo "Configuring MongoDB for local installation..."
echo "Project directory: $PROJECT_DIR"
echo "Data directory: $DATA_DIR"
echo "Log directory: $LOG_DIR"
echo "Config file: $CONFIG_FILE"

# 使用绝对路径更新配置文件
echo "Updating configuration file with absolute paths..."

# 使用 sed 替换配置文件中的路径为绝对路径
sed -i "s|dbPath:.*|dbPath: $DATA_DIR|g" "$CONFIG_FILE"
sed -i "s|path:.*mongod\.log|path: $LOG_DIR/mongod.log|g" "$CONFIG_FILE"

# 修改 bindIp 以允许外部访问
echo "Configuring network access for external connections..."
if grep -q "bindIp:" "$CONFIG_FILE"; then
    # 替换 bindIp 为 0.0.0.0 以允许所有IP访问
    sed -i "s|bindIp:.*|bindIp: 0.0.0.0|g" "$CONFIG_FILE"
else
    # 如果没有 bindIp 配置，在 net 部分添加
    if grep -q "net:" "$CONFIG_FILE"; then
        sed -i "/net:/a\  bindIp: 0.0.0.0" "$CONFIG_FILE"
    else
        # 如果没有 net 部分，添加整个部分
        echo "" >> "$CONFIG_FILE"
        echo "# Network interfaces" >> "$CONFIG_FILE"
        echo "net:" >> "$CONFIG_FILE"
        echo "  port: 27017" >> "$CONFIG_FILE"
        echo "  bindIp: 0.0.0.0" >> "$CONFIG_FILE"
    fi
fi

# 添加或更新 processManagement 部分的 pidFilePath
if grep -q "processManagement:" "$CONFIG_FILE"; then
    # 如果已存在 processManagement 部分，添加或更新 pidFilePath
    if grep -q "pidFilePath:" "$CONFIG_FILE"; then
        sed -i "s|pidFilePath:.*|pidFilePath: $DATA_DIR/mongod.pid|g" "$CONFIG_FILE"
    else
        # 在 processManagement 部分添加 pidFilePath
        sed -i "/processManagement:/a\  pidFilePath: $DATA_DIR/mongod.pid" "$CONFIG_FILE"
    fi
    # 确保有 fork: true
    if ! grep -q "fork:" "$CONFIG_FILE"; then
        sed -i "/processManagement:/a\  fork: true" "$CONFIG_FILE"
    fi
else
    # 如果没有 processManagement 部分，添加整个部分
    echo "" >> "$CONFIG_FILE"
    echo "# Process management" >> "$CONFIG_FILE"
    echo "processManagement:" >> "$CONFIG_FILE"
    echo "  fork: true" >> "$CONFIG_FILE"
    echo "  pidFilePath: $DATA_DIR/mongod.pid" >> "$CONFIG_FILE"
fi

echo "=========================================="
echo "Configuration completed successfully!"
echo "=========================================="
echo "Updated paths in configuration file:"
echo "  - Data path: $DATA_DIR"
echo "  - Log path: $LOG_DIR/mongod.log"
echo "  - PID path: $DATA_DIR/mongod.pid"
echo "  - Port: 27017"
echo "  - Bind IP: 0.0.0.0 (allows external access)"
echo ""
echo "⚠️  SECURITY WARNING:"
echo "MongoDB is now configured to accept connections from any IP address."
echo "Please ensure proper firewall rules and authentication are in place."
echo "For production use, consider:"
echo "  - Enabling authentication (--auth)"
echo "  - Using specific IP addresses instead of 0.0.0.0"
echo "  - Setting up SSL/TLS encryption"
echo "=========================================="
echo "You can now start MongoDB with: ./start.sh"
echo "Configuration backed up to: $BACKUP_CONFIG"
echo ""
echo "Available backups in $CONF_DIR:"
ls -la "$CONF_DIR"/mongod.conf.bak.* 2>/dev/null | awk '{print "  " $9 " (" $5 " bytes, " $6 " " $7 " " $8 ")"}'