#!/usr/bin/env bash

# Akamai CDN刷新工具构建脚本

echo "========== 构建Akamai CDN刷新工具 =========="

# 获取脚本所在目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"
DIST_DIR="$PROJECT_ROOT/dist"

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "❌ Go未安装，请先安装Go语言环境"
    exit 1
fi

echo "Go版本: $(go version)"

# 进入src目录
cd "$SRC_DIR"

# 检查源文件
if [ ! -f "akamai_cdn_refresh.go" ]; then
    echo "❌ 源文件 akamai_cdn_refresh.go 不存在"
    exit 1
fi

# 清理旧文件
echo ""
echo "🧹 清理旧的编译产物..."
rm -f "$PROJECT_ROOT/akamai_cdn_refresh" "$PROJECT_ROOT/akamai_cdn_refresh.exe"
rm -rf "$DIST_DIR"

# 创建输出目录
mkdir -p "$DIST_DIR"

echo ""
echo "� 开始构建..."

# 构建本地平台版本
echo "📱 构建本地平台版本..."
if go build -ldflags="-s -w" -o "$DIST_DIR/akamai_cdn_refresh" akamai_cdn_refresh.go; then
    echo "✅ 构建成功!"
    
    # 确定可执行文件路径
    if [ -f "$DIST_DIR/akamai_cdn_refresh" ]; then
        EXEC="$DIST_DIR/akamai_cdn_refresh"
        EXEC_NAME="akamai_cdn_refresh"
    elif [ -f "$DIST_DIR/akamai_cdn_refresh.exe" ]; then
        EXEC="$DIST_DIR/akamai_cdn_refresh.exe"
        EXEC_NAME="akamai_cdn_refresh.exe"
    fi
    
    echo "可执行文件: $EXEC"
    
    # 复制主配置文件
    echo ""
    echo "📋 复制配置文件..."
    [ -f "$PROJECT_ROOT/conf/akamai.conf" ] && cp "$PROJECT_ROOT/conf/akamai.conf" "$DIST_DIR/" && echo "✅ 已复制 akamai.conf"
    
    echo ""
    echo "========== 使用建议 =========="
    echo "URL刷新: $EXEC --type=url"
    echo "目录刷新: $EXEC --type=directory" 
    echo "CPCode刷新: $EXEC --type=cpcode"
    echo "强制刷新: $EXEC --force"
    echo "预览模式: $EXEC --dry-run"
    
    echo ""
    echo "========== 配置说明 =========="
    echo "主配置文件: $DIST_DIR/akamai.conf"
    echo "URL列表: conf/urls.txt"
    echo "CPCode列表: conf/cpcodes.txt"
    echo "查看帮助: $EXEC --help"
    
else
    echo "❌ 构建失败"
    exit 1
fi