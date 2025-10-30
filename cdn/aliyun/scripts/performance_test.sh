#!/usr/bin/env bash

# OSS极速上传工具性能测试脚本

echo "========== OSS极速上传工具性能测试 =========="

# 获取脚本所在目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 检查可执行文件是否存在
if [ -f "$PROJECT_ROOT/dist/oss_ultra_fast" ]; then
    EXEC="$PROJECT_ROOT/dist/oss_ultra_fast"
elif [ -f "$PROJECT_ROOT/dist/oss_ultra_fast.exe" ]; then
    EXEC="$PROJECT_ROOT/dist/oss_ultra_fast.exe"
else
    echo "❌ 找不到可执行文件！请先运行构建脚本："
    echo "   ./scripts/build_ultra.sh"
    exit 1
fi

echo "🎯 使用可执行文件: $EXEC"

# 解析命令行参数
TEST_SIZE="10"  # 默认测试文件大小(MB)
TEST_MODES="standard,extreme"  # 默认测试模式
CUSTOM_PARAMS=""  # 自定义参数

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--size)
            TEST_SIZE="$2"
            shift 2
            ;;
        -m|--modes)
            TEST_MODES="$2"
            shift 2
            ;;
        -p|--params)
            CUSTOM_PARAMS="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  -s, --size SIZE     测试文件大小(MB)，默认10MB"
            echo "  -m, --modes MODES   测试模式，可选: standard,extreme,custom"
            echo "  -p, --params PARAMS 自定义参数(仅在custom模式下使用)"
            echo "  -h, --help          显示帮助信息"
            echo ""
            echo "示例:"
            echo "  $0                                    # 默认测试"
            echo "  $0 -s 50                             # 50MB文件测试"
            echo "  $0 -m standard,extreme,custom -p \"-s 0.5 -r 100\"  # 完整测试"
            echo "  $0 -m extreme                        # 只测试极限模式"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 -h 查看帮助"
            exit 1
            ;;
    esac
done

echo "📋 测试配置:"
echo "   文件大小: ${TEST_SIZE}MB"
echo "   测试模式: $TEST_MODES"
if [ -n "$CUSTOM_PARAMS" ]; then
    echo "   自定义参数: $CUSTOM_PARAMS"
fi

# 创建临时目录
TEMP_DIR="$PROJECT_ROOT/.temp_test"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# 创建测试文件
echo ""
echo "📁 创建 ${TEST_SIZE}MB 测试文件..."
dd if=/dev/zero of=performance_test.bin bs=1024k count=$TEST_SIZE 2>/dev/null

if [ ! -f "performance_test.bin" ]; then
    echo "❌ 创建测试文件失败"
    exit 1
fi

FILE_SIZE=$(du -h performance_test.bin | cut -f1)
echo "✅ 测试文件创建成功: $FILE_SIZE"

# 测试计数器
TEST_COUNT=0
TOTAL_TESTS=0

# 计算总测试数
IFS=',' read -ra MODES <<< "$TEST_MODES"
for mode in "${MODES[@]}"; do
    ((TOTAL_TESTS++))
done

echo ""
echo "🚀 开始性能测试 (共 $TOTAL_TESTS 项测试)..."

# 执行测试
for mode in "${MODES[@]}"; do
    ((TEST_COUNT++))
    
    case $mode in
        "standard")
            echo ""
            echo "========== 测试 $TEST_COUNT/$TOTAL_TESTS: 标准模式 =========="
            echo "⚙️  配置: 默认分片大小, 50并发"
            start_time=$(date +%s)
            $EXEC performance_test.bin "test/performance_standard_$(date +%s).bin"
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            echo "⏱️  模式耗时: ${duration}秒"
            ;;
            
        "extreme")
            echo ""
            echo "========== 测试 $TEST_COUNT/$TOTAL_TESTS: 极限模式 =========="
            echo "⚙️  配置: 1MB分片, 80并发"
            start_time=$(date +%s)
            $EXEC performance_test.bin "test/performance_extreme_$(date +%s).bin" -x
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            echo "⏱️  模式耗时: ${duration}秒"
            ;;
            
        "custom")
            if [ -n "$CUSTOM_PARAMS" ]; then
                echo ""
                echo "========== 测试 $TEST_COUNT/$TOTAL_TESTS: 自定义模式 =========="
                echo "⚙️  配置: $CUSTOM_PARAMS"
                start_time=$(date +%s)
                $EXEC performance_test.bin "test/performance_custom_$(date +%s).bin" $CUSTOM_PARAMS
                end_time=$(date +%s)
                duration=$((end_time - start_time))
                echo "⏱️  模式耗时: ${duration}秒"
            else
                echo ""
                echo "⚠️  跳过自定义模式: 未提供自定义参数"
                ((TOTAL_TESTS--))
            fi
            ;;
            
        *)
            echo "⚠️  未知测试模式: $mode"
            ;;
    esac
done

# 清理测试文件
echo ""
echo "🧹 清理测试文件..."
rm -f performance_test.bin
cd "$PROJECT_ROOT"
rmdir "$TEMP_DIR" 2>/dev/null

echo ""
echo "✅ 性能测试完成！"
echo ""
echo "📊 测试总结:"
echo "   测试文件: ${TEST_SIZE}MB"
echo "   完成测试: $TEST_COUNT 项"
echo "   测试模式: $TEST_MODES"

echo ""
echo "💡 优化建议:"
echo "   🔹 网络良好时使用极限模式 (-x)"
echo "   🔹 大文件推荐极限模式以获得最佳性能"
echo "   🔹 网络不稳定时可降低并发数 (-r 30)"
echo "   🔹 可尝试不同分片大小 (-s 0.5 或 -s 2)"

echo ""
echo "🎯 使用示例:"
echo "   标准上传: $EXEC file.zip path/file.zip"
echo "   极限性能: $EXEC file.zip path/file.zip -x" 
echo "   自定义配置: $EXEC file.zip path/file.zip -s 0.5 -r 100"