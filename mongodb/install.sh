#! /bin/sh

echo "Installing MongoDB..."

# MongoDB 安装脚本 - 只负责下载和安装，不修改配置
# 配置文件的修改请使用 scripts/config.sh
# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
CONF_DIR="$SCRIPT_DIR/conf"
DATA_DIR="$SCRIPT_DIR/data"
LOG_DIR="$SCRIPT_DIR/logs"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
MONGODB_TAR="mongodb-linux-x86_64-rhel70-7.0.26-rc0.tgz"
MONGODB_DIR="mongodb-linux-x86_64-rhel70-7.0.26-rc0"

# 创建所有必要目录
echo "Creating directory structure..."
mkdir -p "$BIN_DIR"      # MongoDB 二进制文件目录
mkdir -p "$CONF_DIR"     # 配置文件目录
mkdir -p "$DATA_DIR"     # 数据库数据目录
mkdir -p "$LOG_DIR"      # 日志文件目录
mkdir -p "$SCRIPTS_DIR"  # 管理脚本目录

echo "Directory structure created:"
echo "  - Binary directory: $BIN_DIR"
echo "  - Configuration directory: $CONF_DIR"
echo "  - Data directory: $DATA_DIR"
echo "  - Log directory: $LOG_DIR"
echo "  - Scripts directory: $SCRIPTS_DIR"

# 检查本地是否已有MongoDB包
if [ ! -f "$MONGODB_TAR" ]; then
    echo "Downloading MongoDB..."
    wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-7.0.26-rc0.tgz
else
    echo "MongoDB package already exists locally, skipping download."
fi

# 检查是否已解压
if [ ! -d "$MONGODB_DIR" ]; then
    echo "Extracting MongoDB..."
    tar -zxvf "$MONGODB_TAR"
else
    echo "MongoDB already extracted, skipping extraction."
fi

# 复制MongoDB二进制文件到bin目录
cp "$MONGODB_DIR/bin"/* "$BIN_DIR/"

# 下载官方配置文件模板到conf目录（不修改内容）
MONGOD_CONF="$CONF_DIR/mongod.conf"
if [ ! -f "$MONGOD_CONF" ]; then
    echo "Downloading official MongoDB configuration template..."
    # 从MongoDB官方GitHub仓库下载配置文件模板
    wget -O "$MONGOD_CONF" https://raw.githubusercontent.com/mongodb/mongo/master/debian/mongod.conf
    
    if [ $? -eq 0 ]; then
        echo "Official configuration file downloaded to: $MONGOD_CONF"
    else
        echo "Error: Failed to download official configuration file from GitHub"
        echo "Please check your internet connection and try again"
        rm -f "$MONGOD_CONF"  # 删除可能的空文件
        exit 1
    fi
else
    echo "Configuration file already exists: $MONGOD_CONF"
    echo "Skipping configuration file download"
fi

echo "Note: Configuration file uses default system paths"
echo "Run './scripts/config.sh' to configure for local installation"

# # 清理临时文件（保留下载的压缩包，只删除解压目录）
# rm -rf "$MONGODB_DIR"

# 设置执行权限
chmod +x "$BIN_DIR"/*

echo "=========================================="
echo "MongoDB Installation Completed!"
echo "=========================================="
echo "Installation Summary:"
echo "  - MongoDB binaries installed to: $BIN_DIR"
echo "  - Configuration template downloaded to: $MONGOD_CONF"
echo "  - Data directory created: $DATA_DIR"
echo "  - Log directory created: $LOG_DIR"
echo "  - Scripts directory created: $SCRIPTS_DIR"
echo ""
echo "Complete directory structure ready for MongoDB operation"
echo ""
echo "Next steps:"
echo "1. Copy management scripts to: $SCRIPTS_DIR"
echo "2. Run './scripts/config.sh' to configure for local installation"
echo "3. Run './scripts/start.sh' to start MongoDB"
echo "4. Run './scripts/status.sh' to check MongoDB status"
echo "=========================================="