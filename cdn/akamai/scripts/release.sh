#!/usr/bin/env bash

# Akamai CDN刷新工具 - 发布打包脚本

set -e

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项] [平台...]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -a, --all      打包所有平台（默认）"
    echo "  -l, --list     列出所有可用平台"
    echo "  -p, --platform-only  只生成平台独立包"
    echo "  -f, --full-only      只生成完整包"
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
    echo "  $0                                 # 打包所有平台（平台包+完整包）"
    echo "  $0 -a                              # 打包所有平台（平台包+完整包）"
    echo "  $0 -p windows-amd64                # 只生成Windows 64位平台包"
    echo "  $0 -f                              # 只生成完整包"
    echo "  $0 --platform-only darwin-*        # 只生成所有macOS平台包"
    echo "  $0 -l                              # 列出可用平台"
}

# 列出可用平台
list_platforms() {
    echo "检查 dist/ 目录中的可用平台:"
    echo ""
    
    if [ ! -d "dist" ]; then
        echo "❌ dist目录不存在，请先运行构建脚本"
        return 1
    fi
    
    found_any=false
    
    # 定义所有支持的平台
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
        if [[ $platform == *"windows"* ]]; then
            exe_file="dist/akamai_cdn_refresh_${platform}.exe"
        else
            exe_file="dist/akamai_cdn_refresh_${platform}"
        fi
        
        if [ -f "$exe_file" ]; then
            size=$(ls -lh "$exe_file" | awk '{print $5}')
            echo "  ✅ $platform - ${all_platforms[$platform]} ($size)"
            found_any=true
        else
            echo "  ❌ $platform - ${all_platforms[$platform]} (未找到)"
        fi
    done
    
    if [ "$found_any" = false ]; then
        echo "❌ 未找到任何平台的可执行文件"
        echo "💡 请先运行: bash scripts/build_cross_platform.sh"
        return 1
    fi
}

# 创建平台特定的使用说明
create_platform_readme() {
    local target_dir=$1
    local platform=$2
    
    # 定义平台描述
    declare -A platform_descriptions=(
        ["windows-amd64"]="Windows 64位"
        ["windows-arm64"]="Windows ARM64"
        ["darwin-amd64"]="macOS Intel"
        ["darwin-arm64"]="macOS Apple Silicon"
        ["linux-amd64"]="Linux 64位"
        ["linux-arm64"]="Linux ARM64"
        ["linux-386"]="Linux 32位"
    )
    
    local desc="${platform_descriptions[$platform]}"
    
    cat > "$target_dir/QUICK_START.md" << EOF
# Akamai CDN刷新工具 - $desc

## 快速开始

### 1. 配置API凭证
编辑 \`akamai.conf\` 文件，填入您的API凭证。

### 2. 使用示例
EOF

    if [[ $platform == *"windows"* ]]; then
        cat >> "$target_dir/QUICK_START.md" << EOF

\`\`\`cmd
REM 刷新单个文件
akamai_cdn_refresh.exe --force https://cdn.example.com/style.css

REM 预览模式
akamai_cdn_refresh.exe -n https://cdn.example.com/style.css

REM 批量刷新
akamai_cdn_refresh.exe -f urls.txt

REM 查看帮助
akamai_cdn_refresh.exe --help
\`\`\`
EOF
    else
        cat >> "$target_dir/QUICK_START.md" << EOF

\`\`\`bash
# 刷新单个文件
./akamai_cdn_refresh --force https://cdn.example.com/style.css

# 预览模式
./akamai_cdn_refresh -n https://cdn.example.com/style.css

# 批量刷新
./akamai_cdn_refresh -f urls.txt

# 查看帮助
./akamai_cdn_refresh --help
\`\`\`
EOF
    fi

    cat >> "$target_dir/QUICK_START.md" << EOF

### 3. 重要提醒
首次使用前，请在Akamai Control Center激活您的API Client。

详细信息请查看 README.md 文件。
EOF
}

# 解析命令行参数
selected_platforms=()
build_all=true
platform_only=false
full_only=false

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
        -p|--platform-only)
            platform_only=true
            full_only=false
            shift
            ;;
        -f|--full-only)
            full_only=true
            platform_only=false
            shift
            ;;
        *)
            # 处理通配符
            if [[ $1 == *"*"* ]]; then
                # 展开通配符
                pattern=$1
                for file in dist/akamai_cdn_refresh_*; do
                    if [ -f "$file" ]; then
                        basename=$(basename "$file")
                        platform=${basename#akamai_cdn_refresh_}
                        platform=${platform%.exe}
                        if [[ $platform == ${pattern/\*/} ]] || [[ $platform == ${pattern//\*/.*} ]]; then
                            selected_platforms+=("$platform")
                        fi
                    fi
                done
            else
                selected_platforms+=("$1")
            fi
            build_all=false
            shift
            ;;
    esac
done

# 显示交互式菜单（如果没有提供任何选项）
show_interactive_menu() {
    echo ""
    echo "🎯 选择打包选项:"
    echo "================================"
    
    # 首先检查可用平台
    declare -A all_platforms=(
        ["windows-amd64"]="Windows 64位"
        ["windows-arm64"]="Windows ARM64"
        ["darwin-amd64"]="macOS Intel"
        ["darwin-arm64"]="macOS Apple Silicon"
        ["linux-amd64"]="Linux 64位"
        ["linux-arm64"]="Linux ARM64"
        ["linux-386"]="Linux 32位"
    )
    
    # 获取可用平台列表，如果没有dist目录则显示所有平台
    available_platforms=()
    if [ -d "dist" ]; then
        # dist目录存在，检查可用的二进制文件
        for platform in "${!all_platforms[@]}"; do
            if [[ $platform == *"windows"* ]]; then
                exe_file="dist/akamai_cdn_refresh_${platform}.exe"
            else
                exe_file="dist/akamai_cdn_refresh_${platform}"
            fi
            
            if [ -f "$exe_file" ]; then
                size=$(ls -lh "$exe_file" | awk '{print $5}')
                available_platforms+=("$platform:${all_platforms[$platform]}:$size")
            else
                available_platforms+=("$platform:${all_platforms[$platform]}:需构建")
            fi
        done
    else
        # dist目录不存在，显示所有支持的平台
        for platform in "${!all_platforms[@]}"; do
            available_platforms+=("$platform:${all_platforms[$platform]}:需构建")
        done
    fi
    
    # 显示可用平台选项
    option_num=1
    for platform_info in "${available_platforms[@]}"; do
        IFS=':' read -r platform desc size <<< "$platform_info"
        echo "$option_num) $desc ($size)"
        ((option_num++))
    done
    
    echo ""
    echo "$option_num) 只生成完整包"
    ((option_num++))
    echo "$option_num) 生成所有平台包"
    ((option_num++))
    echo "$option_num) 退出"
    echo ""
    read -p "请选择 [1-$((option_num-1))]: " choice
    
    # 处理选择
    if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le $((option_num-1)) ]; then
        if [ $choice -le ${#available_platforms[@]} ]; then
            # 选择了具体平台
            selected_platform_info=${available_platforms[$((choice-1))]}
            IFS=':' read -r platform desc size <<< "$selected_platform_info"
            selected_platforms=("$platform")
            build_all=false
            platform_only=true
            full_only=false
            echo "✅ 已选择: $desc"
        elif [ $choice -eq $((${#available_platforms[@]}+1)) ]; then
            # 只生成完整包
            full_only=true
            platform_only=false
            echo "✅ 已选择: 只生成完整包"
        elif [ $choice -eq $((${#available_platforms[@]}+2)) ]; then
            # 生成所有平台包
            platform_only=true
            full_only=false
            echo "✅ 已选择: 生成所有平台包"
        elif [ $choice -eq $((${#available_platforms[@]}+3)) ]; then
            # 退出
            echo "👋 已退出"
            exit 0
        fi
    else
        echo "❌ 无效选择，请重新选择"
        show_interactive_menu
        return
    fi
}

# 如果没有提供任何参数，显示交互式菜单
if [ ${#selected_platforms[@]} -eq 0 ] && [ "$build_all" = true ] && [ "$platform_only" = false ] && [ "$full_only" = false ]; then
    show_interactive_menu
fi

# 切换到项目根目录
cd "$(dirname "$0")/.."

echo "📦 Akamai CDN刷新工具 - 发布打包"
echo "================================"

# 自动构建所需的二进制文件
echo "🔨 检查并构建二进制文件..."

# 构建函数
build_required_platforms() {
    local platforms_to_check=("$@")
    local need_build=false
    
    # 检查所需平台是否存在
    for platform in "${platforms_to_check[@]}"; do
        if [[ $platform == *"windows"* ]]; then
            exe_file="dist/akamai_cdn_refresh_${platform}.exe"
        else
            exe_file="dist/akamai_cdn_refresh_${platform}"
        fi
        
        if [ ! -f "$exe_file" ]; then
            echo "⚠️ 未找到 $platform 二进制文件"
            need_build=true
        fi
    done
    
    if [ "$need_build" = true ]; then
        echo "🚀 开始自动构建..."
        if [ -f "scripts/build_cross_platform.sh" ]; then
            # 根据需要构建的平台传递参数
            if [ ${#platforms_to_check[@]} -eq 7 ]; then
                # 如果是所有平台，直接调用（默认行为）
                bash scripts/build_cross_platform.sh
            else
                # 如果是特定平台，传递平台参数
                bash scripts/build_cross_platform.sh "${platforms_to_check[@]}"
            fi
            if [ $? -ne 0 ]; then
                echo "❌ 构建失败"
                exit 1
            fi
            echo "✅ 构建完成"
        else
            echo "❌ 构建脚本不存在: scripts/build_cross_platform.sh"
            exit 1
        fi
    else
        echo "✅ 所需二进制文件已存在"
    fi
}

# 根据选择的打包类型确定需要构建的平台
if [ ${#selected_platforms[@]} -gt 0 ]; then
    # 构建选定的平台
    echo "� 准备构建选定平台: ${selected_platforms[*]}"
    build_required_platforms "${selected_platforms[@]}"
elif [ "$full_only" = true ] || [ "$platform_only" = true ]; then
    # 构建所有平台（用于完整包或所有平台包）
    echo "📋 准备构建所有可用平台"
    all_platforms=("windows-amd64" "windows-arm64" "darwin-amd64" "darwin-arm64" "linux-amd64" "linux-arm64" "linux-386")
    build_required_platforms "${all_platforms[@]}"
else
    # 默认构建所有平台
    echo "📋 准备构建所有可用平台"
    all_platforms=("windows-amd64" "windows-arm64" "darwin-amd64" "darwin-arm64" "linux-amd64" "linux-arm64" "linux-386")
    build_required_platforms "${all_platforms[@]}"
fi

# 检查dist目录
if [ ! -d "dist" ]; then
    echo "❌ dist目录不存在，构建可能失败"
    exit 1
fi

# 创建发布目录
RELEASE_DIR="release"
VERSION=$(date +"%Y%m%d_%H%M%S")
RELEASE_NAME="akamai_cdn_refresh_v${VERSION}"

echo "🧹 准备发布目录..."
# 解决 Windows 下 rm -rf 目录被占用问题
if [ -d "$RELEASE_DIR" ]; then
    mv "$RELEASE_DIR" "${RELEASE_DIR}_old_$$" 2>/dev/null || true
    rm -rf "${RELEASE_DIR}_old_$$" 2>/dev/null || rm -rf "$RELEASE_DIR" 2>/dev/null || true
fi
mkdir -p $RELEASE_DIR

echo "📋 发布版本: $RELEASE_NAME"

# 复制文件到发布目录
echo "📂 复制文件..."

# 创建完整版本目录
mkdir -p "$RELEASE_DIR/$RELEASE_NAME"

# 根据打包类型决定复制策略
if [ ${#selected_platforms[@]} -eq 1 ] && [ "$platform_only" = true ]; then
    # 单平台打包：创建简洁的平台目录，不使用版本号
    platform=${selected_platforms[0]}
    echo "📋 单平台模式：创建 $platform 平台包"
    
    # 清理之前的完整版本目录（单平台模式下不需要）
    rm -rf "$RELEASE_DIR/$RELEASE_NAME"
    
    # 直接创建平台目录
    platform_dir="$RELEASE_DIR/akamai_cdn_refresh_${platform}"
    mkdir -p "$platform_dir"
    
    # 复制配置文件
    [ -f conf/akamai.conf ] && cp conf/akamai.conf "$platform_dir/"
    
    # 复制选定平台的可执行文件并重命名为简洁名称
    if [[ $platform == *"windows"* ]]; then
        exe_file="dist/akamai_cdn_refresh_${platform}.exe"
        if [ -f "$exe_file" ]; then
            cp "$exe_file" "$platform_dir/akamai_cdn_refresh.exe"
        fi
    else
        exe_file="dist/akamai_cdn_refresh_${platform}"
        if [ -f "$exe_file" ]; then
            cp "$exe_file" "$platform_dir/akamai_cdn_refresh"
            chmod +x "$platform_dir/akamai_cdn_refresh"
        fi
    fi
    
    # 复制平台指南（如果存在）
    [ -f dist/PLATFORM_GUIDE.md ] && cp dist/PLATFORM_GUIDE.md "$platform_dir/"
    
    # 创建平台特定的使用说明
    create_platform_readme "$platform_dir" "$platform"
else
    # 多平台或完整包：复制完整dist目录
    echo "📋 完整模式：复制所有文件"
    cp -r dist/* "$RELEASE_DIR/$RELEASE_NAME/"
fi

echo ""
echo "📦 创建平台独立包..."

# 创建平台特定的使用说明
create_platform_readme() {
    local target_dir=$1
    local platform=$2
    local desc="${platform_descriptions[$platform]}"
    
    cat > "$target_dir/QUICK_START.md" << EOF
# Akamai CDN刷新工具 - $desc

## 快速开始

### 1. 配置API凭证
编辑 \`akamai.conf\` 文件，填入您的API凭证。

### 2. 使用示例
EOF

    if [[ $platform == *"windows"* ]]; then
        cat >> "$target_dir/QUICK_START.md" << EOF

\`\`\`cmd
REM 刷新单个文件
akamai_cdn_refresh.exe --force https://cdn.example.com/style.css

REM 预览模式
akamai_cdn_refresh.exe -n https://cdn.example.com/style.css

REM 批量刷新
akamai_cdn_refresh.exe -f urls.txt

REM 查看帮助
akamai_cdn_refresh.exe --help
\`\`\`
EOF
    else
        cat >> "$target_dir/QUICK_START.md" << EOF

\`\`\`bash
# 刷新单个文件
./akamai_cdn_refresh --force https://cdn.example.com/style.css

# 预览模式
./akamai_cdn_refresh -n https://cdn.example.com/style.css

# 批量刷新
./akamai_cdn_refresh -f urls.txt

# 查看帮助
./akamai_cdn_refresh --help
\`\`\`
EOF
    fi

    cat >> "$target_dir/QUICK_START.md" << EOF

### 3. 重要提醒
首次使用前，请在Akamai Control Center激活您的API Client。

详细信息请查看 README.md 文件。
EOF
}

# 创建各平台独立包
echo ""
echo "📦 创建平台独立包..."


# 确定要打包的平台
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
    # 自动检测所有可用平台
    platforms_to_build=()
    for platform in "${!platform_descriptions[@]}"; do
        if [[ $platform == *"windows"* ]]; then
            exe_file="dist/akamai_cdn_refresh_${platform}.exe"
        else
            exe_file="dist/akamai_cdn_refresh_${platform}"
        fi
        
        if [ -f "$exe_file" ]; then
            platforms_to_build+=("$platform")
        fi
    done
    
    if [ ${#platforms_to_build[@]} -eq 0 ]; then
        echo "❌ 未找到任何可用的平台文件"
        echo "💡 运行: bash scripts/build_cross_platform.sh"
        exit 1
    fi
    
    echo "🔍 自动检测到 ${#platforms_to_build[@]} 个平台"
else
    # 验证选定的平台
    platforms_to_build=()
    for platform in "${selected_platforms[@]}"; do
        if [[ ! ${platform_descriptions[$platform]+_} ]]; then
            echo "❌ 未知平台: $platform"
            echo "💡 运行: $0 --list 查看可用平台"
            exit 1
        fi
        
        if [[ $platform == *"windows"* ]]; then
            exe_file="dist/akamai_cdn_refresh_${platform}.exe"
        else
            exe_file="dist/akamai_cdn_refresh_${platform}"
        fi
        
        if [ ! -f "$exe_file" ]; then
            echo "❌ 未找到平台文件: $exe_file"
            echo "💡 运行: bash scripts/build_cross_platform.sh"
            exit 1
        fi
        
        platforms_to_build+=("$platform")
    done
    
    echo "🎯 选定平台: ${#platforms_to_build[@]} 个"
fi

# 显示要打包的平台
echo ""
echo "📋 将要打包的平台:"
for platform in "${platforms_to_build[@]}"; do
    echo "  ✅ $platform - ${platform_descriptions[$platform]}"
done

echo ""
echo "📦 创建平台独立包..."

# 如果是单平台模式，跳过平台独立包创建（已经在上面创建了）
if [ ${#selected_platforms[@]} -eq 1 ] && [ "$platform_only" = true ]; then
    echo "  📱 单平台包已创建：akamai_cdn_refresh_${selected_platforms[0]}"
else
    for platform in "${platforms_to_build[@]}"; do
        desc="${platform_descriptions[$platform]}"
        
        echo "  📱 打包 $desc..."
        
        # 创建平台目录
        platform_dir="$RELEASE_DIR/${RELEASE_NAME}_${platform}"
        mkdir -p $platform_dir
        
        # 复制配置文件（只复制akamai.conf）
        if [ -f conf/akamai.conf ]; then
            cp conf/akamai.conf $platform_dir/
        fi
        
        # 复制对应平台的可执行文件
        if [[ $platform == *"windows"* ]]; then
            exe_file="dist/akamai_cdn_refresh_${platform}.exe"
            if [ -f "$exe_file" ]; then
                cp "$exe_file" "$platform_dir/"
                mv "$platform_dir/akamai_cdn_refresh_${platform}.exe" "$platform_dir/akamai_cdn_refresh.exe"
            else
                echo "⚠️ 跳过 $desc（未找到 $exe_file）"
                rm -rf "$platform_dir"
                continue
            fi
        else
            exe_file="dist/akamai_cdn_refresh_${platform}"
            if [ -f "$exe_file" ]; then
                cp "$exe_file" "$platform_dir/"
                mv "$platform_dir/akamai_cdn_refresh_${platform}" "$platform_dir/akamai_cdn_refresh"
                chmod +x "$platform_dir/akamai_cdn_refresh"
            else
                echo "⚠️ 跳过 $desc（未找到 $exe_file）"
                rm -rf "$platform_dir"
                continue
            fi
        fi
        
        # 创建平台特定的使用说明
        create_platform_readme "$platform_dir" "$platform"
    done
fi

# 根据选项决定创建哪种包
if [ "$full_only" = true ]; then
    # 只创建完整包
    echo ""
    echo "📦 创建完整发布包..."
    
    cd "$RELEASE_DIR"
    
    # 尝试创建压缩包（优先ZIP，备用TAR.GZ）
    if command -v zip &> /dev/null; then
        echo "  🗜️ 创建ZIP压缩包..."
        zip -r "${RELEASE_NAME}.zip" $RELEASE_NAME/ > /dev/null
        echo "     ✅ ${RELEASE_NAME}.zip"
    elif command -v tar &> /dev/null; then
        echo "  🗜️ 创建TAR.GZ压缩包..."
        tar -czf "${RELEASE_NAME}.tar.gz" $RELEASE_NAME/
        echo "     ✅ ${RELEASE_NAME}.tar.gz"
    else
        echo "  ⚠️ 未找到压缩工具（zip/tar），跳过完整包压缩"
        echo "     💡 你可以手动打包 $RELEASE_NAME/ 目录"
    fi
    
elif [ "$platform_only" = true ]; then
    # 只创建平台独立包
    echo ""
    echo "📦 创建平台独立压缩包..."
    
    cd "$RELEASE_DIR"
    
    # 如果是单平台模式，处理简洁的目录名
    if [ ${#selected_platforms[@]} -eq 1 ]; then
        platform=${selected_platforms[0]}
        platform_dir="akamai_cdn_refresh_${platform}"
        
        if [ -d "$platform_dir" ]; then
            if [[ $platform == *"windows"* ]]; then
                # Windows平台优先创建ZIP
                if command -v zip &> /dev/null; then
                    zip -r "${platform_dir}.zip" $platform_dir/ > /dev/null
                    echo "  📦 ${platform_dir}.zip"
                elif command -v tar &> /dev/null; then
                    tar -czf "${platform_dir}.tar.gz" $platform_dir/
                    echo "  📦 ${platform_dir}.tar.gz"
                else
                    echo "  ⚠️ 跳过 ${platform_dir} 压缩（未找到压缩工具）"
                fi
            else
                # Unix平台优先创建TAR.GZ
                if command -v tar &> /dev/null; then
                    tar -czf "${platform_dir}.tar.gz" $platform_dir/
                    echo "  📦 ${platform_dir}.tar.gz"
                elif command -v zip &> /dev/null; then
                    zip -r "${platform_dir}.zip" $platform_dir/ > /dev/null
                    echo "  📦 ${platform_dir}.zip"
                else
                    echo "  ⚠️ 跳过 ${platform_dir} 压缩（未找到压缩工具）"
                fi
            fi
        fi
    else
        # 多平台选择模式
        for platform in "${platforms_to_build[@]}"; do
            desc="${platform_descriptions[$platform]}"
            
            platform_dir="${RELEASE_NAME}_${platform}"
            
            if [ -d "$platform_dir" ]; then
                if [[ $platform == *"windows"* ]]; then
                    # Windows平台优先创建ZIP
                    if command -v zip &> /dev/null; then
                        zip -r "${platform_dir}.zip" $platform_dir/ > /dev/null
                        echo "  📦 ${platform_dir}.zip"
                    elif command -v tar &> /dev/null; then
                        tar -czf "${platform_dir}.tar.gz" $platform_dir/
                        echo "  📦 ${platform_dir}.tar.gz"
                    else
                        echo "  ⚠️ 跳过 ${platform_dir} 压缩（未找到压缩工具）"
                    fi
                else
                    # Unix平台优先创建TAR.GZ
                    if command -v tar &> /dev/null; then
                        tar -czf "${platform_dir}.tar.gz" $platform_dir/
                        echo "  📦 ${platform_dir}.tar.gz"
                    elif command -v zip &> /dev/null; then
                        zip -r "${platform_dir}.zip" $platform_dir/ > /dev/null
                        echo "  📦 ${platform_dir}.zip"
                    else
                        echo "  ⚠️ 跳过 ${platform_dir} 压缩（未找到压缩工具）"
                    fi
                fi
            fi
        done
    fi
    
else
    # 默认：创建完整包和平台独立包
    echo ""
    echo "📦 创建完整发布包..."
    
    cd "$RELEASE_DIR"
    
    # 尝试创建压缩包（优先ZIP，备用TAR.GZ）
    if command -v zip &> /dev/null; then
        echo "  🗜️ 创建ZIP压缩包..."
        zip -r "${RELEASE_NAME}.zip" $RELEASE_NAME/ > /dev/null
        echo "     ✅ ${RELEASE_NAME}.zip"
    elif command -v tar &> /dev/null; then
        echo "  🗜️ 创建TAR.GZ压缩包..."
        tar -czf "${RELEASE_NAME}.tar.gz" $RELEASE_NAME/
        echo "     ✅ ${RELEASE_NAME}.tar.gz"
    else
        echo "  ⚠️ 未找到压缩工具（zip/tar），跳过完整包压缩"
        echo "     💡 你可以手动打包 $RELEASE_NAME/ 目录"
    fi
    
    # 为每个平台创建独立压缩包
    echo ""
    echo "📦 创建平台独立压缩包..."
    
    for platform in "${platforms_to_build[@]}"; do
        desc="${platform_descriptions[$platform]}"
        
        platform_dir="${RELEASE_NAME}_${platform}"
        
        if [ -d "$platform_dir" ]; then
            if [[ $platform == *"windows"* ]]; then
                # Windows平台优先创建ZIP
                if command -v zip &> /dev/null; then
                    zip -r "${platform_dir}.zip" $platform_dir/ > /dev/null
                    echo "  📦 ${platform_dir}.zip"
                elif command -v tar &> /dev/null; then
                    tar -czf "${platform_dir}.tar.gz" $platform_dir/
                    echo "  📦 ${platform_dir}.tar.gz"
                else
                    echo "  ⚠️ 跳过 ${platform_dir} 压缩（未找到压缩工具）"
                fi
            else
                # Unix平台优先创建TAR.GZ
                if command -v tar &> /dev/null; then
                    tar -czf "${platform_dir}.tar.gz" $platform_dir/
                    echo "  📦 ${platform_dir}.tar.gz"
                elif command -v zip &> /dev/null; then
                    zip -r "${platform_dir}.zip" $platform_dir/ > /dev/null
                    echo "  📦 ${platform_dir}.zip"
                else
                    echo "  ⚠️ 跳过 ${platform_dir} 压缩（未找到压缩工具）"
                fi
            fi
        fi
    done
fi

cd ..

# 显示结果
echo ""
echo "🎉 发布包创建完成!"
echo "📁 发布目录: $RELEASE_DIR"
echo ""
echo "📋 生成的文件:"
if ls -lh $RELEASE_DIR/ 2>/dev/null; then
    echo ""
else
    echo "  (无文件生成)"
fi

# 检查是否有压缩包生成
compressed_files=$(find $RELEASE_DIR -name "*.zip" -o -name "*.tar.gz" 2>/dev/null | wc -l)

echo "💡 使用说明:"
if [ $compressed_files -gt 0 ]; then
    echo "  - 压缩包: 可直接分发的打包文件"
    echo "  - 目录: release/ 下的各平台目录可直接使用"
else
    echo "  - 各平台目录: release/ 下可直接使用"
    echo "  - 手动压缩: 如需压缩包，请安装 zip 或 tar 工具"
fi

echo ""
echo "📱 平台目录:"
if [ ${#selected_platforms[@]} -eq 1 ] && [ "$platform_only" = true ]; then
    platform=${selected_platforms[0]}
    platform_dir="$RELEASE_DIR/akamai_cdn_refresh_${platform}"
    if [ -d "$platform_dir" ]; then
        echo "  ✅ ${platform_descriptions[$platform]}: akamai_cdn_refresh_${platform}/"
    fi
else
    for platform in "${platforms_to_build[@]}"; do
        platform_dir="$RELEASE_DIR/${RELEASE_NAME}_${platform}"
        if [ -d "$platform_dir" ]; then
            echo "  ✅ ${platform_descriptions[$platform]}: ${RELEASE_NAME}_${platform}/"
        fi
    done
fi

echo ""
echo "🚀 发布完成!"

# 成功退出
exit 0