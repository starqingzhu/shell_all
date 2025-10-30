#! /bin/sh

echo "Installing MongoDB Shell Client..."

# MongoDB 客户端安装脚本
# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

# MongoDB Shell 下载信息
MONGOSH_VERSION="2.1.0"
MONGOSH_TAR="mongosh-${MONGOSH_VERSION}-linux-x64.tgz"
MONGOSH_URL="https://downloads.mongodb.com/compass/${MONGOSH_TAR}"
MONGOSH_DIR="mongosh-${MONGOSH_VERSION}-linux-x64"

echo "MongoDB Shell Client Installation"
echo "=================================="
echo "Target directory: $BIN_DIR"
echo "Version: $MONGOSH_VERSION"
echo "Platform: Linux x64"
echo ""

# 创建bin目录（如果不存在）
mkdir -p "$BIN_DIR"

# 检查是否已经安装了客户端
if [ -f "$BIN_DIR/mongosh" ] || [ -f "$BIN_DIR/mongo" ]; then
    echo "MongoDB client already installed:"
    [ -f "$BIN_DIR/mongosh" ] && echo "  - mongosh: $(ls -la "$BIN_DIR/mongosh" | awk '{print $5 " bytes"}')"
    [ -f "$BIN_DIR/mongo" ] && echo "  - mongo: $(ls -la "$BIN_DIR/mongo" | awk '{print $5 " bytes"}')"
    echo ""
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# 检查本地是否已有MongoDB Shell包
if [ ! -f "$MONGOSH_TAR" ]; then
    echo "Downloading MongoDB Shell..."
    echo "URL: $MONGOSH_URL"
    
    # 尝试下载
    if command -v wget >/dev/null 2>&1; then
        wget "$MONGOSH_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$MONGOSH_TAR" "$MONGOSH_URL"
    else
        echo "Error: Neither wget nor curl found"
        echo "Please install wget or curl to download MongoDB Shell"
        exit 1
    fi
    
    # 检查下载是否成功
    if [ ! -f "$MONGOSH_TAR" ]; then
        echo "Error: Failed to download MongoDB Shell"
        echo "Please check your internet connection and try again"
        exit 1
    fi
    
    echo "MongoDB Shell downloaded successfully"
else
    echo "MongoDB Shell package already exists locally, skipping download"
fi

# 检查是否已解压
if [ ! -d "$MONGOSH_DIR" ]; then
    echo "Extracting MongoDB Shell..."
    tar -zxvf "$MONGOSH_TAR"
    
    if [ ! -d "$MONGOSH_DIR" ]; then
        echo "Error: Failed to extract MongoDB Shell"
        exit 1
    fi
    
    echo "MongoDB Shell extracted successfully"
else
    echo "MongoDB Shell already extracted, skipping extraction"
fi

# 复制mongosh到bin目录
if [ -f "$MONGOSH_DIR/bin/mongosh" ]; then
    echo "Installing mongosh to $BIN_DIR..."
    cp "$MONGOSH_DIR/bin/mongosh" "$BIN_DIR/"
    chmod +x "$BIN_DIR/mongosh"
    echo "mongosh installed successfully"
else
    echo "Error: mongosh binary not found in extracted package"
    exit 1
fi

# 检查是否有其他有用的工具
if [ -d "$MONGOSH_DIR/bin" ]; then
    echo "Checking for additional tools..."
    for tool in mongo mongoimport mongoexport mongodump mongorestore; do
        if [ -f "$MONGOSH_DIR/bin/$tool" ]; then
            echo "Installing $tool..."
            cp "$MONGOSH_DIR/bin/$tool" "$BIN_DIR/"
            chmod +x "$BIN_DIR/$tool"
        fi
    done
fi

# 清理临时文件（可选）
echo ""
read -p "Clean up downloaded files? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Cleaning up temporary files..."
    rm -rf "$MONGOSH_DIR"
    rm -f "$MONGOSH_TAR"
    echo "Cleanup completed"
fi

# 验证安装
echo ""
echo "=================================="
echo "Installation completed!"
echo "=================================="
echo "Installed MongoDB client tools:"

if [ -f "$BIN_DIR/mongosh" ]; then
    echo "✓ mongosh: $("$BIN_DIR/mongosh" --version 2>/dev/null | head -n 1 || echo "installed")"
fi

if [ -f "$BIN_DIR/mongo" ]; then
    echo "✓ mongo: $("$BIN_DIR/mongo" --version 2>/dev/null | head -n 1 || echo "installed")"
fi

# 列出所有安装的工具
echo ""
echo "All available tools in $BIN_DIR:"
ls -la "$BIN_DIR" | grep -E "(mongo|mongo)" | awk '{print "  " $9 " (" $5 " bytes)"}'

echo ""
echo "Usage:"
echo "  Connect to MongoDB: ./scripts/condb.sh"
echo "  Manual connection: $BIN_DIR/mongosh --host <host> --port <port>"
echo "=================================="