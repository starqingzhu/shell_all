#!/usr/bin/env bash
# Akamai CDN Refresh Tool - Cross-platform Build Script (Selective Platform Support)

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
    echo "  linux-386      : Linux 32位"
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
        ["linux-386"]="Linux 32位"
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
    echo "  7) Linux 32位 (linux-386)"
    echo "  8) 所有Windows平台"
    echo "  9) 所有macOS平台"
    echo " 10) 所有Linux平台"
    echo " 11) 所有平台"
    echo "  0) 退出"
    echo ""
    read -p "请输入选项 (0-11): " choice
    
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
            selected_platforms=("linux-386")
            ;;
        8)
            selected_platforms=("windows-amd64" "windows-arm64")
            ;;
        9)
            selected_platforms=("darwin-amd64" "darwin-arm64")
            ;;
        10)
            selected_platforms=("linux-amd64" "linux-arm64" "linux-386")
            ;;
        11)
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
                    selected_platforms+=("linux-amd64" "linux-arm64" "linux-386")
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
echo " Akamai CDN Refresh Tool - Cross-platform Build"
echo "==============================================="

# Get script and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"
DIST_DIR="$PROJECT_ROOT/dist"

# Check Go environment
if ! command -v go &> /dev/null; then
    echo "[ERROR] Go not found. Please install Go."
    exit 1
fi

echo "Go version: $(go version)"

# Clean and create dist directory
echo ""
echo "[CLEAN] Cleaning dist directory..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Enter source directory
cd "$SRC_DIR"

# Build targets: All major platforms
declare -A targets=(
    ["windows-amd64"]="windows amd64 .exe"
    ["windows-arm64"]="windows arm64 .exe"
    ["darwin-amd64"]="darwin amd64 "
    ["darwin-arm64"]="darwin arm64 "
    ["linux-amd64"]="linux amd64 "
    ["linux-arm64"]="linux arm64 "
    ["linux-386"]="linux 386 "
)

# 确定要编译的平台
declare -A platform_descriptions=(
    ["windows-amd64"]="Windows 64位"
    ["windows-arm64"]="Windows ARM64"
    ["darwin-amd64"]="macOS Intel"
    ["darwin-arm64"]="macOS Apple Silicon"
    ["linux-amd64"]="Linux 64位"
    ["linux-arm64"]="Linux ARM64"
    ["linux-386"]="Linux 32位"
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
    output_name="akamai_cdn_refresh_${target}${ext}"
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
        "linux-386")
            echo "   Platform: Linux 32-bit (x86)"
            ;;
    esac
    
    env GOOS=$os GOARCH=$arch CGO_ENABLED=0 go build -ldflags="-s -w" -o "$output_path" akamai_cdn_refresh.go
    if [ $? -eq 0 ]; then
        size=$(du -h "$output_path" | cut -f1)
        echo "   [OK] Success: $output_name ($size)"
        ((success_count++))
    else
        echo "   [FAIL] Failed: $target"
    fi
done

cd "$PROJECT_ROOT"

# Copy config files
echo ""
echo "[COPY] Copying config files to dist/ ..."
[ -f conf/akamai.conf ] && cp conf/akamai.conf dist/ && echo "   [OK] conf/akamai.conf"

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
echo "   cd dist && akamai_cdn_refresh_windows-amd64.exe --help"
echo "   # Windows ARM64:"
echo "   cd dist && akamai_cdn_refresh_windows-arm64.exe --help"
echo "   # macOS Intel:"
echo "   cd dist && ./akamai_cdn_refresh_darwin-amd64 --help"
echo "   # macOS Apple Silicon:"
echo "   cd dist && ./akamai_cdn_refresh_darwin-arm64 --help"
echo "   # Linux 64-bit:"
echo "   cd dist && ./akamai_cdn_refresh_linux-amd64 --help"
echo "   # Linux ARM64:"
echo "   cd dist && ./akamai_cdn_refresh_linux-arm64 --help"
echo "   # Linux 32-bit:"
echo "   cd dist && ./akamai_cdn_refresh_linux-386 --help"
echo ""
echo "[DONE] Build finished. All files are in dist/"

# Create platform-specific README
create_platform_readme() {
    cat > "$DIST_DIR/PLATFORM_GUIDE.md" << 'EOF'
# Akamai CDN Refresh Tool - Platform Guide

## 📱 Platform Support

| Platform | Architecture | Binary Name | Description |
|----------|-------------|-------------|-------------|
| Windows | x64 (Intel/AMD) | `akamai_cdn_refresh_windows-amd64.exe` | Standard Windows 64-bit |
| Windows | ARM64 | `akamai_cdn_refresh_windows-arm64.exe` | Windows on ARM (Surface Pro X, etc.) |
| macOS | x64 (Intel) | `akamai_cdn_refresh_darwin-amd64` | Intel-based Mac |
| macOS | ARM64 (Apple Silicon) | `akamai_cdn_refresh_darwin-arm64` | M1/M2/M3/M4 Mac |
| Linux | x64 (Intel/AMD) | `akamai_cdn_refresh_linux-amd64` | Standard Linux 64-bit |
| Linux | ARM64 | `akamai_cdn_refresh_linux-arm64` | ARM64 Linux (Raspberry Pi 4, etc.) |
| Linux | x86 (32-bit) | `akamai_cdn_refresh_linux-386` | Legacy 32-bit Linux |

## 🚀 Quick Start

### Windows
```cmd
# Download and run
cd dist
akamai_cdn_refresh_windows-amd64.exe --help
```

### macOS
```bash
# Make executable and run
cd dist
chmod +x akamai_cdn_refresh_darwin-arm64  # or darwin-amd64 for Intel Mac
./akamai_cdn_refresh_darwin-arm64 --help
```

### Linux
```bash
# Make executable and run
cd dist
chmod +x akamai_cdn_refresh_linux-amd64  # or other Linux variant
./akamai_cdn_refresh_linux-amd64 --help
```

## ⚙️ Configuration

All platforms use the same configuration files:
- `akamai.conf` - Main configuration
- `url.json` - URL refresh configuration
- `urls.txt` - URL list
- `cpcodes.txt` - CPCode list

## 🎯 Usage Examples

### URL Refresh
```bash
./akamai_cdn_refresh_[platform] --type=url
```

### Directory Refresh
```bash
./akamai_cdn_refresh_[platform] --type=directory
```

### CPCode Refresh
```bash
./akamai_cdn_refresh_[platform] --type=cpcode
```

## 📞 Support

For issues or questions, please check the main README.md file.
EOF

    echo "[INFO] Created platform guide: $DIST_DIR/PLATFORM_GUIDE.md"
}

# Create platform guide
create_platform_readme

# Exit with success if at least one build succeeded
if [ $success_count -gt 0 ]; then
    exit 0
else
    exit 1
fi