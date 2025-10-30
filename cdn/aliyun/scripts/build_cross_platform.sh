#!/usr/bin/env bash
# OSS极速上传工具 - 跨平台构建脚本 (选择性平台支持)

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项] [平台...]"
    echo ""
    echo "如果不提供任何参数，将显示交互式平台选择菜单"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -a, --all      编译所有平台（默认）"
    echo "  -l, --list     列出所有支持的平台"
    echo ""
    echo "可用平台:"
    echo "  windows-amd64  : Windows 64位"
    echo "  windows-arm64  : Windows ARM64"
    echo "  darwin-amd64   : macOS Intel"
    echo "  darwin-arm64   : macOS Apple Silicon"
    echo "  linux-amd64    : Linux 64位"
    echo "  linux-arm64    : Linux ARM64"
    echo ""
    echo "示例:"
    echo "  $0                                 # 显示交互式菜单"
    echo "  $0 -a                              # 编译所有平台"
    echo "  $0 windows-amd64                   # 只编译Windows 64位"
    echo "  $0 windows-amd64 darwin-arm64      # 编译Windows 64位和macOS Apple Silicon"
    echo "  $0 darwin-*                        # 编译所有macOS平台"
    echo "  $0 -l                              # 列出支持的平台"
}

# 列出支持的平台
list_platforms() {
    echo "支持的编译平台:"
    echo ""
    declare -A all_platforms=(
        ["windows-amd64"]="Windows 64位"
        ["windows-arm64"]="Windows ARM64"
        ["darwin-amd64"]="macOS Intel"
        ["darwin-arm64"]="macOS Apple Silicon"
        ["linux-amd64"]="Linux 64位"
        ["linux-arm64"]="Linux ARM64"
    )
    
    for platform in "${!all_platforms[@]}"; do
        echo "  ✅ $platform - ${all_platforms[$platform]}"
    done
}

# 显示交互式平台选择菜单
show_platform_menu() {
    echo ""
    echo "请选择要编译的平台:"
    echo ""
    echo "  1) Windows 64位 (windows-amd64)"
    echo "  2) Windows ARM64 (windows-arm64)"
    echo "  3) macOS Intel (darwin-amd64)"
    echo "  4) macOS Apple Silicon (darwin-arm64)"
    echo "  5) Linux 64位 (linux-amd64)"
    echo "  6) Linux ARM64 (linux-arm64)"
    echo "  7) 所有Windows平台"
    echo "  8) 所有macOS平台"
    echo "  9) 所有Linux平台"
    echo " 10) 所有平台"
    echo "  0) 退出"
    echo ""
    read -p "请输入选项 (0-10): " choice
    
    case $choice in
        1)
            selected_platforms=("windows-amd64")
            ;;
        2)
            selected_platforms=("windows-arm64")
            ;;
        3)
            selected_platforms=("darwin-amd64")
            ;;
        4)
            selected_platforms=("darwin-arm64")
            ;;
        5)
            selected_platforms=("linux-amd64")
            ;;
        6)
            selected_platforms=("linux-arm64")
            ;;
        7)
            selected_platforms=("windows-amd64" "windows-arm64")
            ;;
        8)
            selected_platforms=("darwin-amd64" "darwin-arm64")
            ;;
        9)
            selected_platforms=("linux-amd64" "linux-arm64")
            ;;
        10)
            build_all=true
            return
            ;;
        0)
            echo "已取消编译"
            exit 0
            ;;
        *)
            echo "[ERROR] 无效选项: $choice"
            exit 1
            ;;
    esac
    
    build_all=false
}

# 解析命令行参数
selected_platforms=()
build_all=true

# 如果没有参数，显示交互式菜单
if [[ $# -eq 0 ]]; then
    show_platform_menu
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            list_platforms
            exit 0
            ;;
        -a|--all)
            build_all=true
            shift
            ;;
        *)
            # 处理通配符
            if [[ $1 == *"*"* ]]; then
                # 展开通配符
                pattern=$1
                if [[ $pattern == "darwin-*" ]]; then
                    selected_platforms+=("darwin-amd64" "darwin-arm64")
                elif [[ $pattern == "windows-*" ]]; then
                    selected_platforms+=("windows-amd64" "windows-arm64")
                elif [[ $pattern == "linux-*" ]]; then
                    selected_platforms+=("linux-amd64" "linux-arm64")
                fi
            else
                selected_platforms+=("$1")
            fi
            build_all=false
            shift
            ;;
    esac
done

echo "==============================================="
echo " OSS极速上传工具 - 跨平台构建"
echo "==============================================="

# 获取脚本所在目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"
DIST_DIR="$PROJECT_ROOT/dist"

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "[ERROR] Go not found. Please install Go."
    exit 1
fi

echo "Go version: $(go version)"

# 进入src目录
cd "$SRC_DIR"

# 检查源文件
if [ ! -f "oss_ultra_fast.go" ]; then
    echo "[ERROR] 源文件 oss_ultra_fast.go 不存在"
    echo "[INFO] 请先运行: ./scripts/generate_code.sh"
    exit 1
fi

# 清理旧文件和创建输出目录
echo ""
echo "[CLEAN] Cleaning dist directory..."
rm -f "$PROJECT_ROOT/oss_ultra_fast" "$PROJECT_ROOT/oss_ultra_fast.exe"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 检查依赖
echo ""
echo "[DEPS] 检查和下载依赖..."
if [ ! -f "go.mod" ]; then
    echo "初始化Go模块..."
    go mod init oss-ultra-fast
fi

go mod tidy

# 定义编译目标
declare -A targets=(
    ["windows-amd64"]="windows amd64 .exe"
    ["windows-arm64"]="windows arm64 .exe"
    ["darwin-amd64"]="darwin amd64 "
    ["darwin-arm64"]="darwin arm64 "
    ["linux-amd64"]="linux amd64 "
    ["linux-arm64"]="linux arm64 "
)

# 确定要编译的平台
declare -A platform_descriptions=(
    ["windows-amd64"]="Windows 64位"
    ["windows-arm64"]="Windows ARM64"
    ["darwin-amd64"]="macOS Intel"
    ["darwin-arm64"]="macOS Apple Silicon"
    ["linux-amd64"]="Linux 64位"
    ["linux-arm64"]="Linux ARM64"
)

if [ "$build_all" = true ]; then
    # 编译所有平台
    platforms_to_build=("${!targets[@]}")
    echo ""
    echo "[INFO] 编译所有平台 (${#platforms_to_build[@]} 个)"
else
    # 验证选定的平台
    platforms_to_build=()
    for platform in "${selected_platforms[@]}"; do
        if [[ ! ${targets[$platform]+_} ]]; then
            echo "[ERROR] 未知平台: $platform"
            echo "[INFO] 运行: $0 --list 查看支持的平台"
            exit 1
        fi
        platforms_to_build+=("$platform")
    done
    
    echo ""
    echo "[INFO] 编译选定平台 (${#platforms_to_build[@]} 个)"
fi

# 显示要编译的平台
echo ""
echo "[PLATFORMS] 将要编译的平台:"
for platform in "${platforms_to_build[@]}"; do
    echo "  ✅ $platform - ${platform_descriptions[$platform]}"
done

success_count=0
total_count=${#platforms_to_build[@]}

echo ""
echo "[BUILD] Start building binaries..."

for target in "${platforms_to_build[@]}"; do
    IFS=' ' read -r os arch ext <<< "${targets[$target]}"
    output_name="oss_ultra_fast_${target}${ext}"
    output_path="$DIST_DIR/$output_name"
    echo "[BUILD] $os/$arch -> $output_name"
    
    # Add platform description
    case $target in
        "windows-amd64")
            echo "   Platform: Windows 64-bit (Intel/AMD)"
            ;;
        "windows-arm64")
            echo "   Platform: Windows ARM64 (Surface Pro X, etc.)"
            ;;
        "darwin-amd64")
            echo "   Platform: macOS Intel (x86_64)"
            ;;
        "darwin-arm64")
            echo "   Platform: macOS Apple Silicon (M1/M2/M3/M4)"
            ;;
        "linux-amd64")
            echo "   Platform: Linux 64-bit (Intel/AMD)"
            ;;
        "linux-arm64")
            echo "   Platform: Linux ARM64 (Raspberry Pi 4, etc.)"
            ;;
    esac
    
    env GOOS=$os GOARCH=$arch CGO_ENABLED=0 go build -ldflags="-s -w" -o "$output_path" oss_ultra_fast.go
    if [ $? -eq 0 ]; then
        size=$(du -h "$output_path" | cut -f1)
        echo "   [OK] Success: $output_name ($size)"
        ((success_count++))
    else
        echo "   [FAIL] Failed: $target"
    fi
done

cd "$PROJECT_ROOT"

# Show build summary
echo ""
echo "==============================================="
echo " Build Summary: $success_count / $total_count succeeded"
echo "==============================================="
if [ -d "$DIST_DIR" ] && [ "$(ls -A $DIST_DIR 2>/dev/null)" ]; then
    ls -lh dist/ | grep -v "^total" | awk '{printf "   %s  %s\n", $5, $9}'
else
    echo "   No files generated"
fi

echo ""
echo "[USAGE] Examples by platform:"
echo "   # Windows 64-bit:"
echo "   cd dist && oss_ultra_fast_windows-amd64.exe file.zip remote/file.zip -x"
echo "   # Windows ARM64:"
echo "   cd dist && oss_ultra_fast_windows-arm64.exe file.zip remote/file.zip -x"
echo "   # macOS Intel:"
echo "   cd dist && ./oss_ultra_fast_darwin-amd64 file.zip remote/file.zip -x"
echo "   # macOS Apple Silicon:"
echo "   cd dist && ./oss_ultra_fast_darwin-arm64 file.zip remote/file.zip -x"
echo "   # Linux 64-bit:"
echo "   cd dist && ./oss_ultra_fast_linux-amd64 file.zip remote/file.zip -x"
echo "   # Linux ARM64:"
echo "   cd dist && ./oss_ultra_fast_linux-arm64 file.zip remote/file.zip -x"
echo ""
echo "[DONE] Build finished. All files are in dist/"

# Create platform-specific README
create_platform_readme() {
    cat > "$DIST_DIR/PLATFORM_GUIDE.md" << 'EOF'
# OSS极速上传工具 - 平台使用指南

## 📱 平台支持

| 平台 | 架构 | 二进制文件名 | 描述 |
|----------|-------------|-------------|-------------|
| Windows | x64 (Intel/AMD) | `oss_ultra_fast_windows-amd64.exe` | 标准Windows 64位 |
| Windows | ARM64 | `oss_ultra_fast_windows-arm64.exe` | Windows ARM (Surface Pro X, 等) |
| macOS | x64 (Intel) | `oss_ultra_fast_darwin-amd64` | Intel Mac |
| macOS | ARM64 (Apple Silicon) | `oss_ultra_fast_darwin-arm64` | M1/M2/M3/M4 Mac |
| Linux | x64 (Intel/AMD) | `oss_ultra_fast_linux-amd64` | 标准Linux 64位 |
| Linux | ARM64 | `oss_ultra_fast_linux-arm64` | ARM64 Linux (树莓派4, 等) |

## 🚀 快速开始

### Windows
```cmd
# 下载并运行
cd dist
oss_ultra_fast_windows-amd64.exe file.zip remote/file.zip -x
```

### macOS
```bash
# 设置可执行权限并运行
cd dist
chmod +x oss_ultra_fast_darwin-arm64  # 或 darwin-amd64 for Intel Mac
./oss_ultra_fast_darwin-arm64 file.zip remote/file.zip -x
```

### Linux
```bash
# 设置可执行权限并运行
cd dist
chmod +x oss_ultra_fast_linux-amd64  # 或其他Linux变体
./oss_ultra_fast_linux-amd64 file.zip remote/file.zip -x
```

## ⚙️ 配置方法

所有平台使用相同的配置方法:

### 方式1: 环境变量
```bash
export OSS_ACCESS_KEY_ID="your_access_key_id"
export OSS_ACCESS_KEY_SECRET="your_access_key_secret"
export OSS_ENDPOINT="oss-cn-hongkong.aliyuncs.com"
export OSS_BUCKET="oss-mh"
```

### 方式2: ossutil配置文件
程序会自动读取 `~/.ossutilconfig` 文件

## 🎯 使用示例

### 文件上传
```bash
./oss_ultra_fast_[platform] video.mp4 media/video.mp4 -x
```

### 目录上传
```bash
./oss_ultra_fast_[platform] ./src/ project/src/ -d -x
```

### 自定义参数
```bash
./oss_ultra_fast_[platform] file.zip backups/file.zip -s 1 -r 80 -x
```

## 📊 性能特点

- 🚀 比ossutil快10-20倍
- ⚡ 支持1MB小分片 + 80并发
- 💥 平均速度: 1-3 MB/s
- 📁 支持目录递归上传

## 📞 支持

如有问题或疑问，请查看主README.md文件。
EOF

    echo "[INFO] Created platform guide: $DIST_DIR/PLATFORM_GUIDE.md"
}

# 创建性能测试脚本  
create_test_script() {
    cat > "$DIST_DIR/performance_test.sh" << 'EOF'
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
EOF

    chmod +x "$DIST_DIR/performance_test.sh"
    echo "[INFO] Created test script: $DIST_DIR/performance_test.sh"
}

# Create platform guide
if [ $success_count -gt 0 ]; then
    create_platform_readme
    
    # 创建性能测试脚本
    create_test_script
    
    echo ""
    echo "🎯 重点推荐:"
    if [ -f "dist/oss_ultra_fast_darwin-arm64" ]; then
        echo "  📱 Mac M4: dist/oss_ultra_fast_darwin-arm64"
    fi
    if [ -f "dist/oss_ultra_fast_windows-amd64.exe" ]; then
        echo "  🪟 Windows: dist/oss_ultra_fast_windows-amd64.exe"
    fi
    
    echo ""
    echo "📋 配置方法:"
    echo "  方式1: 环境变量"
    echo "    export OSS_ACCESS_KEY_ID=\"your_key\""
    echo "    export OSS_ACCESS_KEY_SECRET=\"your_secret\""
    echo "    export OSS_ENDPOINT=\"oss-cn-hongkong.aliyuncs.com\""
    echo "    export OSS_BUCKET=\"oss-mh\""
    echo ""
    echo "  方式2: 使用已配置的ossutil"
    echo "    程序会自动读取 ~/.ossutilconfig"
    
    echo ""
    echo "🎉 跨平台编译完成！"
    echo "📁 所有文件都在 $DIST_DIR 目录中"
    exit 0
else
    echo ""
    echo "❌ 编译失败，请检查错误信息"
    exit 1
fi

echo ""
echo "🎉 跨平台编译完成！"
echo "📁 所有文件都在 $DIST_DIR 目录中"
