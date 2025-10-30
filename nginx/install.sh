#! /bin/sh

# Install script for the application
# Nginx版本配置
NGINX_VERSION="1.28.0"

# ===========================================
# 路径配置 - 在任何目录切换之前就确定路径
# ===========================================

# 获取当前脚本所在目录的绝对路径
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 安装目录配置 - 使用脚本所在目录
INSTALL_PREFIX="${SCRIPT_DIR}"
SBIN_PATH="${INSTALL_PREFIX}/bin/nginx"
CONF_PATH="${INSTALL_PREFIX}/conf/nginx.conf"
ERROR_LOG_PATH="${INSTALL_PREFIX}/logs/error.log"
ACCESS_LOG_PATH="${INSTALL_PREFIX}/logs/access.log"
PID_PATH="${INSTALL_PREFIX}/run/nginx.pid"

# 临时目录配置
TEMP_DIR="${INSTALL_PREFIX}/temp"
CLIENT_BODY_TEMP="${TEMP_DIR}/client_body_temp"
PROXY_TEMP="${TEMP_DIR}/proxy_temp"
FASTCGI_TEMP="${TEMP_DIR}/fastcgi_temp"
UWSGI_TEMP="${TEMP_DIR}/uwsgi_temp"
SCGI_TEMP="${TEMP_DIR}/scgi_temp"

echo "Starting installation..."
echo "Nginx version: ${NGINX_VERSION}"
echo "Script directory: ${SCRIPT_DIR}"
echo "Install directory: ${INSTALL_PREFIX}"

# 构建下载URL和文件名 - 使用nginx官方源码包
NGINX_TAR="nginx-${NGINX_VERSION}.tar.gz"
NGINX_URL="http://nginx.org/download/${NGINX_TAR}"
NGINX_EXTRACT_DIR="nginx-${NGINX_VERSION}"

echo "Download URL: ${NGINX_URL}"
echo "Extract directory: ${NGINX_EXTRACT_DIR}"

# 检查现有文件状态
echo ""
echo "=== 检查现有文件状态 ==="
if [ -f "package/${NGINX_TAR}" ]; then
    echo "✓ 源码包已存在: package/${NGINX_TAR}"
    PACKAGE_EXISTS=true
else
    echo "- 源码包不存在，需要下载"
    PACKAGE_EXISTS=false
fi

if [ -d "package/${NGINX_EXTRACT_DIR}" ]; then
    echo "✓ 源码目录已存在: package/${NGINX_EXTRACT_DIR}"
    EXTRACT_EXISTS=true
else
    echo "- 源码目录不存在，需要解压"
    EXTRACT_EXISTS=false
fi
echo ""

#nginx源码包下载在package目录下
echo "创建package目录..."
mkdir -p package/

# 检查源码包是否已存在
if [ -f "package/${NGINX_TAR}" ]; then
    echo "✓ nginx源码包已存在: package/${NGINX_TAR}"
    echo "跳过下载步骤..."
else
    echo "下载nginx源码包..."
    wget -c "${NGINX_URL}" -P package/

    if [ $? -ne 0 ]; then
        echo "✗ nginx源码下载失败"
        echo "请检查网络连接或手动下载: ${NGINX_URL}"
        exit 1
    fi
    echo "✓ nginx源码包下载完成"
fi

# 检查是否已解压
if [ -d "package/${NGINX_EXTRACT_DIR}" ]; then
    echo "✓ nginx源码已解压: package/${NGINX_EXTRACT_DIR}"
    echo "跳过解压步骤..."
else
    echo "解压nginx源码包..."
    tar -zxvf "package/${NGINX_TAR}" -C package/

    if [ $? -ne 0 ]; then
        echo "✗ nginx源码解压失败"
        exit 1
    fi
    echo "✓ nginx源码包解压完成"
fi

echo "检查解压后的目录..."
if [ ! -d "package/${NGINX_EXTRACT_DIR}" ]; then
    echo "✗ 解压目录不存在: package/${NGINX_EXTRACT_DIR}"
    echo "package目录内容:"
    ls -la package/
    exit 1
fi

echo "✓ 源码目录准备就绪: package/${NGINX_EXTRACT_DIR}"

cd "package/${NGINX_EXTRACT_DIR}/"

echo "Nginx source package extracted."
echo "Current directory: $(pwd)"

echo "=== 编译安装配置 ==="
echo "脚本目录: ${SCRIPT_DIR}"
echo "安装目录: ${INSTALL_PREFIX}"
echo "可执行文件: ${SBIN_PATH}"
echo "配置文件: ${CONF_PATH}"
echo "当前工作目录: $(pwd)"
echo ""

# 验证路径设置
echo "=== 路径验证 ==="
echo "安装目录绝对路径: $(realpath ${INSTALL_PREFIX})"
echo "当前源码目录: $(pwd)"
if [ "$(realpath ${INSTALL_PREFIX})" = "$(pwd)" ]; then
    echo "✗ 警告: 安装目录与源码目录相同，这会导致冲突"
fi
echo ""

# ===========================================
# 检查编译依赖
# ===========================================

echo "=== 检查编译依赖 ==="

# 检查必要的编译工具
MISSING_DEPS=()

if ! command -v gcc >/dev/null 2>&1; then
    MISSING_DEPS+=("gcc")
fi

if ! command -v make >/dev/null 2>&1; then
    MISSING_DEPS+=("make")
fi

if ! command -v pcre-config >/dev/null 2>&1; then
    MISSING_DEPS+=("pcre-devel")
fi

if ! command -v openssl >/dev/null 2>&1; then
    MISSING_DEPS+=("openssl-devel")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "⚠ 缺少编译依赖:"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "安装命令:"
    echo "  sudo yum groupinstall -y 'Development Tools'"
    echo "  sudo yum install -y pcre-devel openssl-devel zlib-devel wget"
    echo ""
    read -p "是否现在自动安装依赖? (y/N): " INSTALL_DEPS
    if [ "$INSTALL_DEPS" = "y" ] || [ "$INSTALL_DEPS" = "Y" ]; then
        echo "正在安装编译依赖..."
        sudo yum groupinstall -y 'Development Tools'
        sudo yum install -y pcre-devel openssl-devel zlib-devel wget
        if [ $? -ne 0 ]; then
            echo "✗ 依赖安装失败"
            exit 1
        fi
        echo "✓ 依赖安装完成"
    else
        echo "请先安装必要的编译依赖后再运行此脚本"
        exit 1
    fi
else
    echo "✓ 编译依赖检查通过"
fi

# ===========================================
# 配置编译参数
# ===========================================

echo ""
echo "=== 配置编译参数 ==="

# 编译配置参数
CONFIGURE_ARGS="
--prefix=${INSTALL_PREFIX}
--sbin-path=${SBIN_PATH}
--conf-path=${CONF_PATH}
--error-log-path=${ERROR_LOG_PATH}
--http-log-path=${ACCESS_LOG_PATH}
--pid-path=${PID_PATH}
--lock-path=${INSTALL_PREFIX}/logs/nginx.lock
--http-client-body-temp-path=${CLIENT_BODY_TEMP}
--http-proxy-temp-path=${PROXY_TEMP}
--http-fastcgi-temp-path=${FASTCGI_TEMP}
--http-uwsgi-temp-path=${UWSGI_TEMP}
--http-scgi-temp-path=${SCGI_TEMP}
--with-http_ssl_module
--with-http_realip_module
--with-http_addition_module
--with-http_sub_module
--with-http_dav_module
--with-http_flv_module
--with-http_mp4_module
--with-http_gunzip_module
--with-http_gzip_static_module
--with-http_random_index_module
--with-http_secure_link_module
--with-http_stub_status_module
--with-http_auth_request_module
--with-file-aio
--with-http_v2_module
--user=$(whoami)
--group=$(whoami)
"

echo "编译配置参数:"
echo "$CONFIGURE_ARGS"
echo ""

# ===========================================
# 备份现有安装
# ===========================================

echo "=== 检查现有安装并备份 ==="

# 创建备份目录
BACKUP_BASE_DIR="${INSTALL_PREFIX}/backup"
BACKUP_DATE=$(date +%Y%m%d)
BACKUP_TIME=$(date +%H%M%S)

if [ -f "$SBIN_PATH" ]; then
    echo "发现现有nginx安装: $SBIN_PATH"
    
    # 获取当前nginx版本
    CURRENT_VERSION=$("$SBIN_PATH" -v 2>&1 | grep -o "nginx/[0-9.]*" | cut -d'/' -f2 2>/dev/null || echo "unknown")
    echo "当前nginx版本: $CURRENT_VERSION"
    echo "目标安装版本: $NGINX_VERSION"
    
    # 创建备份目录
    mkdir -p "$BACKUP_BASE_DIR"
    
    # 备份nginx二进制文件
    NGINX_BACKUP_FILE="${BACKUP_BASE_DIR}/nginx_${CURRENT_VERSION}_${BACKUP_DATE}_${BACKUP_TIME}"
    echo "备份nginx二进制到: $NGINX_BACKUP_FILE"
    cp "$SBIN_PATH" "$NGINX_BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "✓ nginx二进制文件已备份"
        
        # 显示备份信息
        echo ""
        echo "备份摘要:"
        echo "  备份目录: $BACKUP_BASE_DIR"
        echo "  二进制备份: $(basename $NGINX_BACKUP_FILE)"
        
        # 显示历史备份
        BACKUP_COUNT=$(ls -1 "$BACKUP_BASE_DIR"/nginx_* 2>/dev/null | wc -l)
        if [ $BACKUP_COUNT -gt 0 ]; then
            echo "  历史备份数量: $BACKUP_COUNT"
            echo "  最近备份文件:"
            ls -1t "$BACKUP_BASE_DIR"/nginx_* 2>/dev/null | head -3 | while read backup_file; do
                echo "    $(basename $backup_file)"
            done
        fi
        
    else
        echo "⚠ nginx二进制备份失败，但继续安装..."
    fi
    
else
    echo "未发现现有nginx安装"
fi

echo ""

# ===========================================
# 开始编译安装
# ===========================================

echo "=== 开始编译安装 ==="

# 1. 检查是否已配置
echo "1. 检查编译配置状态..."
echo "当前目录: $(pwd)"

if [ ! -f "./configure" ]; then
    echo "⚠ 在当前目录中未找到 configure 文件"
    echo "目录内容:"
    ls -la
    echo ""
    echo "这是正常的，nginx官方源码包包含configure文件"
    echo "如果没有configure文件，说明下载的可能是GitHub源码"
    exit 1
fi

echo "✓ 找到configure文件"

# 检查是否已经配置过
if [ -f "Makefile" ]; then
    echo "✓ 检测到Makefile，已配置过编译环境"
    echo "跳过配置步骤..."
else
    echo "开始配置编译环境..."
    ./configure $CONFIGURE_ARGS

    if [ $? -ne 0 ]; then
        echo "✗ nginx配置失败"
        echo "请检查编译依赖和配置参数"
        exit 1
    fi
    echo "✓ nginx配置成功"
fi

# 2. 检查是否已编译
echo ""
echo "2. 检查编译状态..."

# 检查是否已经编译过（存在nginx可执行文件）
if [ -f "objs/nginx" ]; then
    echo "✓ 检测到已编译的nginx文件: objs/nginx"
    echo "跳过编译步骤..."
    ALREADY_COMPILED=true
else
    echo "开始编译nginx (可能需要几分钟)..."
    CPU_CORES=$(nproc 2>/dev/null || echo "2")
    echo "使用 ${CPU_CORES} 个CPU核心并行编译"

    make -j${CPU_CORES}

    if [ $? -ne 0 ]; then
        echo "✗ nginx编译失败"
        exit 1
    fi
    echo "✓ nginx编译成功"
    ALREADY_COMPILED=false
fi

# 3. 安装检查
echo ""
echo "3. 检查安装状态..."
echo "安装目标目录: $INSTALL_PREFIX"
echo "当前工作目录: $(pwd)"

# 确保安装目录存在且不同于源码目录
if [ "$(realpath $INSTALL_PREFIX)" = "$(pwd)" ]; then
    echo "✗ 错误: 安装目录不能与源码目录相同"
    echo "源码目录: $(pwd)"
    echo "安装目录: $(realpath $INSTALL_PREFIX)"
    echo "这会导致文件冲突"
    exit 1
fi

# 检查是否已经安装过相同版本的nginx
if [ -f "$SBIN_PATH" ]; then
    INSTALLED_VERSION=$("$SBIN_PATH" -v 2>&1 | grep -o "nginx/[0-9.]*" | cut -d'/' -f2)
    if [ "$INSTALLED_VERSION" = "$NGINX_VERSION" ]; then
        echo "✓ 检测到已安装相同版本的nginx: $INSTALLED_VERSION"
        read -p "是否重新安装? (y/N): " REINSTALL
        if [ "$REINSTALL" != "y" ] && [ "$REINSTALL" != "Y" ]; then
            echo "跳过安装步骤，使用现有安装"
            SKIP_INSTALL=true
        else
            echo "开始重新安装..."
            SKIP_INSTALL=false
        fi
    else
        echo "⚠ 检测到不同版本的nginx: $INSTALLED_VERSION (目标版本: $NGINX_VERSION)"
        echo "继续安装新版本..."
        SKIP_INSTALL=false
    fi
else
    echo "未检测到已安装的nginx，开始安装..."
    SKIP_INSTALL=false
fi

if [ "$SKIP_INSTALL" != "true" ]; then
    # 创建安装目录
    mkdir -p "$INSTALL_PREFIX"

    echo "开始安装nginx..."
    make install

    if [ $? -ne 0 ]; then
        echo "✗ nginx安装失败"
        exit 1
    fi
    echo "✓ nginx安装成功"
else
    echo "✓ 使用现有nginx安装"
fi

# ===========================================
# 创建必要目录
# ===========================================

echo ""
echo "=== 创建必要目录 ==="

# 创建临时目录
mkdir -p "$TEMP_DIR"
mkdir -p "$CLIENT_BODY_TEMP"
mkdir -p "$PROXY_TEMP"
mkdir -p "$FASTCGI_TEMP"
mkdir -p "$UWSGI_TEMP"
mkdir -p "$SCGI_TEMP"

# 创建日志目录
mkdir -p "${INSTALL_PREFIX}/logs"

# 创建运行时目录
mkdir -p "${INSTALL_PREFIX}/run"

# 创建scripts目录
mkdir -p "${INSTALL_PREFIX}/scripts"

# 创建scripts/ssl目录（用于SSL脚本）
mkdir -p "${INSTALL_PREFIX}/scripts/ssl"

# 创建scripts/conf目录（用于配置文件管理）
mkdir -p "${INSTALL_PREFIX}/scripts/conf"

# 创建SSL目录
mkdir -p "${INSTALL_PREFIX}/ssl"

# 设置目录权限
chown -R $(whoami):$(whoami) "$INSTALL_PREFIX" 2>/dev/null || echo "⚠ 权限设置失败，请手动设置"

echo "✓ 目录结构创建完成"

# ===========================================
# 验证安装
# ===========================================

echo ""
echo "=== 验证安装结果 ==="

if [ -f "$SBIN_PATH" ]; then
    echo "✓ nginx可执行文件: $SBIN_PATH"
    
    # 显示版本信息
    NGINX_VERSION_INFO=$("$SBIN_PATH" -v 2>&1)
    echo "  版本: $NGINX_VERSION_INFO"
    
    # 显示编译模块
    echo ""
    echo "编译模块信息:"
    "$SBIN_PATH" -V 2>&1 | grep -E "(configure arguments|built)"
    
    # 检查SSL模块
    if "$SBIN_PATH" -V 2>&1 | grep -q "with-http_ssl_module"; then
        echo "✓ SSL模块: 已启用"
    else
        echo "✗ SSL模块: 未启用"
    fi
    
else
    echo "✗ nginx安装失败: 可执行文件不存在"
    exit 1
fi

if [ -f "$CONF_PATH" ]; then
    echo "✓ 配置文件: $CONF_PATH"
else
    echo "⚠ 配置文件不存在，将使用默认配置"
fi

# 测试配置文件语法
echo ""
echo "测试nginx配置..."
if "$SBIN_PATH" -t -c "$CONF_PATH" 2>/dev/null; then
    echo "✓ nginx配置语法正确"
else
    echo "⚠ nginx配置语法检查失败 (可能需要SSL证书)"
fi

# ===========================================
# 安装完成
# ===========================================

echo ""
echo "================================================="
echo "nginx编译安装完成！"
echo "================================================="
echo ""

# 显示执行步骤统计
echo "=== 执行步骤统计 ==="
if [ "$PACKAGE_EXISTS" = "true" ]; then
    echo "✓ 源码包下载: 已跳过（文件已存在）"
else
    echo "✓ 源码包下载: 已完成"
fi

if [ "$EXTRACT_EXISTS" = "true" ]; then
    echo "✓ 源码解压: 已跳过（目录已存在）"
else
    echo "✓ 源码解压: 已完成"
fi

if [ -f "package/${NGINX_EXTRACT_DIR}/Makefile" ]; then
    echo "✓ 编译配置: 已跳过（Makefile已存在）"
else
    echo "✓ 编译配置: 已完成"
fi

if [ "$ALREADY_COMPILED" = "true" ]; then
    echo "✓ 源码编译: 已跳过（nginx已编译）"
else
    echo "✓ 源码编译: 已完成"
fi

if [ "$SKIP_INSTALL" = "true" ]; then
    echo "✓ 软件安装: 已跳过（用户选择）"
else
    echo "✓ 软件安装: 已完成"
fi

echo ""
echo "安装信息:"
echo "  安装目录: $INSTALL_PREFIX"
echo "  可执行文件: $SBIN_PATH"
echo "  配置文件: $CONF_PATH"
echo "  日志目录: ${INSTALL_PREFIX}/logs"
echo "  运行时目录: ${INSTALL_PREFIX}/run"
echo "  脚本目录: ${INSTALL_PREFIX}/scripts"
echo "  SSL脚本目录: ${INSTALL_PREFIX}/scripts/ssl"
echo "  配置管理目录: ${INSTALL_PREFIX}/scripts/conf"
echo "  SSL目录: ${INSTALL_PREFIX}/ssl"
if [ -n "$NGINX_BACKUP_FILE" ] && [ -f "$NGINX_BACKUP_FILE" ]; then
    echo "  备份文件: $NGINX_BACKUP_FILE"
fi
echo ""
echo "下一步操作:"
echo "1. 配置nginx.conf文件"
echo "2. 初始化SSL证书: cd scripts && ./init_ssl.sh"
echo "3. 启动nginx服务: cd scripts && ./start.sh"
echo "4. 部署HTTPS配置: cd scripts && ./quick_deploy_https.sh"
echo ""
echo "管理命令:"
echo "  $SBIN_PATH -t          # 测试配置"
echo "  $SBIN_PATH -s reload   # 重载配置"
echo "  $SBIN_PATH -s stop     # 停止服务"
echo ""

if [ -n "$NGINX_BACKUP_FILE" ] && [ -f "$NGINX_BACKUP_FILE" ]; then
    echo "备份管理:"
    echo "  备份文件: $NGINX_BACKUP_FILE"
    echo "  恢复命令: cp $NGINX_BACKUP_FILE $SBIN_PATH"
    echo "  查看所有备份: ls -la ${BACKUP_BASE_DIR}/nginx_*"
    echo "  备份文件命名: nginx_版本_日期_时间"
    echo ""
fi

echo "nginx安装脚本执行完成！"