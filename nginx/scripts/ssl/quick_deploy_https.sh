#!/bin/bash

# HTTPS快速部署脚本 - 简化版
# 专注于SSL证书创建和nginx HTTPS配置

# 获取脚本所在目录并加载SSL配置
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 如果在ssl目录下运行，SCRIPT_DIR应该是ssl目录
# 如果从其他地方运行，需要找到ssl目录
if [ ! -f "${SCRIPT_DIR}/ssl_config.sh" ]; then
    # 可能是从上级目录运行的，尝试ssl子目录
    if [ -f "${SCRIPT_DIR}/ssl/ssl_config.sh" ]; then
        SCRIPT_DIR="${SCRIPT_DIR}/ssl"
    else
        echo "✗ 找不到ssl_config.sh文件"
        echo "当前目录: $SCRIPT_DIR"
        echo "目录内容:"
        ls -la "$SCRIPT_DIR"
        exit 1
    fi
fi

echo "✓ SSL脚本目录: $SCRIPT_DIR"

# 检查必要的脚本文件是否存在
if [ ! -f "${SCRIPT_DIR}/init_ssl.sh" ]; then
    echo "✗ 找不到init_ssl.sh: ${SCRIPT_DIR}/init_ssl.sh"
    echo "当前目录内容:"
    ls -la "$SCRIPT_DIR"
    exit 1
fi

# 保存SSL脚本目录，因为ssl_config.sh会重新定义SCRIPT_DIR
SSL_SCRIPT_DIR="$SCRIPT_DIR"

source "${SCRIPT_DIR}/ssl_config.sh"

echo "=== HTTPS快速部署脚本 ==="
echo "自动配置SSL证书并启用HTTPS服务"
echo ""

# 显示当前配置
echo "当前配置:"
echo "  nginx主目录: $NGINX_HOME"
echo "  nginx可执行文件: $NGINX_BIN"
echo "  SSL证书目录: $SSL_DIR"
echo ""

read -p "确认开始HTTPS部署? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "部署已取消"
    exit 0
fi

echo ""
echo "=== 步骤1: 检查nginx环境 ==="

# 检查nginx可执行文件
if [ ! -f "$NGINX_BIN" ]; then
    echo "✗ nginx未安装: $NGINX_BIN"
    echo "请先运行 install.sh 安装nginx"
    exit 1
fi

# 检查SSL模块支持
if ! "$NGINX_BIN" -V 2>&1 | grep -q "with-http_ssl_module"; then
    echo "✗ nginx未编译SSL模块支持"
    echo "需要重新编译nginx并启用SSL模块"
    exit 1
fi

echo "✓ nginx环境检查通过"

echo ""
echo "=== 步骤2: 检查OpenSSL工具 ==="

if ! check_openssl; then
    echo "请安装OpenSSL: sudo yum install -y openssl"
    exit 1
fi

echo ""
echo "=== 步骤3: 初始化SSL证书 ==="

# 检查现有证书
if check_ssl_certificates >/dev/null 2>&1; then
    echo "发现现有SSL证书"
    read -p "是否重新生成SSL证书? (y/N): " RENEW
    if [ "$RENEW" = "y" ] || [ "$RENEW" = "Y" ]; then
        echo "重新生成SSL证书..."
        bash "${SSL_SCRIPT_DIR}/init_ssl.sh"
    else
        echo "使用现有SSL证书"
    fi
else
    echo "创建新的SSL证书..."
    bash "${SSL_SCRIPT_DIR}/init_ssl.sh"
fi

if [ $? -ne 0 ]; then
    echo "✗ SSL证书初始化失败"
    exit 1
fi

echo ""
echo "=== 步骤4: 验证SSL证书 ==="

if ! check_ssl_certificates >/dev/null 2>&1; then
    echo "✗ SSL证书验证失败"
    exit 1
fi

echo "✓ SSL证书验证通过"

echo ""
echo "=== 步骤5: 测试nginx配置 ==="

# 测试nginx配置语法
if "$NGINX_BIN" -t -c "$NGINX_CONF" >/dev/null 2>&1; then
    echo "✓ nginx配置语法正确"
else
    echo "⚠ nginx配置语法检查失败"
    echo "请检查nginx配置文件中的SSL配置"
fi

echo ""
echo "=== 步骤6: 重启nginx服务 ==="

# 切换到scripts目录执行重启脚本
NGINX_SCRIPTS_DIR=$(dirname "$SCRIPT_DIR")
cd "$NGINX_SCRIPTS_DIR"

if [ -f "restart.sh" ]; then
    ./restart.sh
    if [ $? -eq 0 ]; then
        echo "✓ nginx重启成功"
    else
        echo "✗ nginx重启失败"
        exit 1
    fi
else
    echo "⚠ 重启脚本不存在，请手动重启nginx"
fi

echo ""
echo "=== HTTPS部署完成 ==="
echo ""
echo "SSL证书信息:"
echo "  证书文件: $SSL_CERT"
echo "  私钥文件: $SSL_KEY"
echo "  证书类型: 自签名证书"
echo ""
echo "管理命令:"
echo "  ./manage_ssl.sh check   # 检查SSL状态"
echo "  ./manage_ssl.sh info    # 查看证书信息"
echo "  ./manage_ssl.sh renew   # 重新生成证书"
echo ""
echo "注意事项:"
echo "- 使用自签名证书，浏览器会显示安全警告"
echo "- 生产环境请使用正式CA签发的证书"
echo "- 确保nginx配置文件中正确配置了SSL"