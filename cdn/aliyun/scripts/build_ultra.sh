#!/usr/bin/env bash

# 极速版本OSS上传工具构建脚本 12345678

echo "========== 构建极速版本OSS上传工具 =========="

# 获取脚本所在目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"

# 创建src目录（如果不存在）
mkdir -p "$SRC_DIR"

# 进入src目录
cd "$SRC_DIR"

# 清理所有文件
echo "清理文件..."
rm -f oss_ultra_fast oss_ultra_fast.exe go.mod go.sum .oss_checkpoint/*

# 生成Go代码
echo ""
echo "生成Go代码..."
"$SCRIPT_DIR/generate_code.sh" -f

echo "下载依赖..."
go mod tidy

# 创建dist目录（如果不存在）
DIST_DIR="$PROJECT_ROOT/dist"
mkdir -p "$DIST_DIR"

# 清理旧的可执行文件
echo "清理旧的可执行文件..."
rm -f "$PROJECT_ROOT/oss_ultra_fast" "$PROJECT_ROOT/oss_ultra_fast.exe"

echo ""
echo "构建极速版本..."
if go build -o "$DIST_DIR/oss_ultra_fast" oss_ultra_fast.go; then
    echo "✅ 构建成功!"
    
    if [ -f "$DIST_DIR/oss_ultra_fast" ]; then
        EXEC="$DIST_DIR/oss_ultra_fast"
        EXEC_NAME="oss_ultra_fast"
    elif [ -f "$DIST_DIR/oss_ultra_fast.exe" ]; then
        EXEC="$DIST_DIR/oss_ultra_fast.exe"
        EXEC_NAME="oss_ultra_fast.exe"
    fi
    
    echo "可执行文件: $EXEC"
    
    echo ""
    echo "========== 使用建议 =========="
    echo "普通使用: $EXEC file.zip path/file.zip"
    echo "极限性能: $EXEC file.zip path/file.zip -x"
    echo "自定义参数: $EXEC file.zip path/file.zip -s 0.5 -r 100"
    
    echo ""
    echo "========== 性能测试 =========="
    echo "运行性能测试: ./scripts/performance_test.sh"
    echo "查看测试选项: ./scripts/performance_test.sh -h"
    
else
    echo "❌ 构建失败"
    exit 1
fi