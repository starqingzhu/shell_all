#!/usr/bin/env bash

# OSS极速上传工具性能测试脚本

echo "🚀 OSS极速上传工具性能测试"

# 检测平台
OS=$(uname -s)
ARCH=$(uname -m)

case $OS in
    "Darwin")
        case $ARCH in
            "arm64"|"aarch64")
                EXEC="./oss_ultra_fast_darwin-arm64"
                PLATFORM="Mac ARM64 (M1/M2/M3/M4)"
                ;;
            "x86_64")
                EXEC="./oss_ultra_fast_darwin-amd64"
                PLATFORM="Mac Intel"
                ;;
        esac
        ;;
    "Linux")
        case $ARCH in
            "arm64"|"aarch64")
                EXEC="./oss_ultra_fast_linux-arm64"
                PLATFORM="Linux ARM64"
                ;;
            "x86_64")
                EXEC="./oss_ultra_fast_linux-amd64"
                PLATFORM="Linux x64"
                ;;
        esac
        ;;
    *)
        echo "❌ 不支持的平台: $OS"
        echo "请手动选择对应的可执行文件:"
        ls -1 oss_ultra_fast_*
        exit 1
        ;;
esac

if [ ! -f "$EXEC" ]; then
    echo "❌ 找不到可执行文件: $EXEC"
    echo "可用文件:"
    ls -1 oss_ultra_fast_* 2>/dev/null || echo "  无可执行文件"
    exit 1
fi

echo "📱 检测到平台: $PLATFORM"
echo "🎯 使用程序: $EXEC"

# 创建测试文件
echo ""
echo "📋 创建10MB测试文件..."
dd if=/dev/zero of=perf_test.bin bs=1024k count=10 2>/dev/null

echo ""
echo "⚡ 执行性能测试..."
echo "测试命令: $EXEC perf_test.bin test/performance_test.bin -x"
echo ""

time $EXEC perf_test.bin test/performance_test.bin -x

# 清理
rm -f perf_test.bin

echo ""
echo "✅ 性能测试完成"
echo ""
echo "💡 提示:"
echo "  - 如需测试目录上传: $EXEC ./local_dir/ remote/dir/ -d -x"
echo "  - 如需自定义参数: $EXEC file.zip remote/file.zip -s 1 -r 100 -x"
