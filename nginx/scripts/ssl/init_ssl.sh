#!/bin/bash

# SSL证书初始化脚本
# 创建自签名SSL证书用于HTTPS

# 获取脚本所在目录并加载SSL配置
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "${SCRIPT_DIR}/ssl_config.sh"

echo "=== SSL证书初始化脚本 ==="
echo "生成自签名SSL证书用于HTTPS服务"
echo ""

# 显示配置信息
show_ssl_config
echo ""

# 检查OpenSSL工具
if ! check_openssl; then
    exit 1
fi

# 创建SSL目录
create_ssl_directories

# 备份现有证书
if [ -f "$SSL_CERT" ] || [ -f "$SSL_KEY" ]; then
    echo "发现现有SSL证书文件"
    read -p "是否备份现有证书并重新生成? (y/N): " CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        backup_ssl_certificates
    else
        echo "操作已取消"
        exit 0
    fi
fi

echo ""
echo "=== 生成SSL证书 ==="

# 询问用户是否生成SAN扩展证书
echo "SSL证书类型选择:"
echo "1) 标准SSL证书 (仅支持通用名称)"
echo "2) SAN扩展SSL证书 (支持多个域名和IP地址)"
echo ""
read -p "请选择证书类型 (1/2，默认为2): " CERT_TYPE

# 默认选择SAN扩展证书
if [ -z "$CERT_TYPE" ]; then
    CERT_TYPE="2"
fi

case "$CERT_TYPE" in
    "1")
        echo "选择: 标准SSL证书"
        USE_SAN=false
        ;;
    "2")
        echo "选择: SAN扩展SSL证书"
        USE_SAN=true
        ;;
    *)
        echo "无效选择，使用默认的SAN扩展证书"
        USE_SAN=true
        ;;
esac

echo ""

# 生成私钥
echo "1. 生成SSL私钥..."
openssl genrsa -out "$SSL_KEY" $SSL_KEY_LENGTH

if [ $? -ne 0 ]; then
    echo "✗ SSL私钥生成失败"
    exit 1
fi

echo "✓ SSL私钥生成成功: $SSL_KEY"

# 生成证书签名请求（CSR）
echo "2. 生成证书签名请求..."

if [ "$USE_SAN" = true ]; then
    # 创建临时配置文件用于SAN扩展
    TEMP_CONF=$(mktemp)
    cat > "$TEMP_CONF" << EOF
[req]
default_bits = $SSL_KEY_LENGTH
prompt = no
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
C=$SSL_COUNTRY
ST=$SSL_STATE
L=$SSL_CITY
O=$SSL_ORG
OU=$SSL_UNIT
CN=$SSL_COMMON_NAME
emailAddress=$SSL_EMAIL

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = $SSL_COMMON_NAME
DNS.3 = nginx.local
DNS.4 = api.local
DNS.5 = ssl.local
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

    openssl req -new -key "$SSL_KEY" -out "${SSL_DIR}/nginx.csr" -config "$TEMP_CONF"
else
    # 标准证书签名请求（不包含SAN扩展）
    openssl req -new -key "$SSL_KEY" -out "${SSL_DIR}/nginx.csr" -subj "/C=${SSL_COUNTRY}/ST=${SSL_STATE}/L=${SSL_CITY}/O=${SSL_ORG}/OU=${SSL_UNIT}/CN=${SSL_COMMON_NAME}/emailAddress=${SSL_EMAIL}"
fi

if [ $? -ne 0 ]; then
    echo "✗ 证书签名请求生成失败"
    exit 1
fi

echo "✓ 证书签名请求生成成功"

# 生成自签名证书
if [ "$USE_SAN" = true ]; then
    echo "3. 生成自签名证书(包含SAN扩展)..."
    openssl x509 -req -days $SSL_DAYS -in "${SSL_DIR}/nginx.csr" -signkey "$SSL_KEY" -out "$SSL_CERT" \
        -extensions v3_req -extfile "$TEMP_CONF"
    
    if [ $? -ne 0 ]; then
        echo "✗ SSL证书生成失败"
        rm -f "$TEMP_CONF"
        exit 1
    fi
    
    # 清理临时配置文件
    rm -f "$TEMP_CONF"
else
    echo "3. 生成标准自签名证书..."
    openssl x509 -req -days $SSL_DAYS -in "${SSL_DIR}/nginx.csr" -signkey "$SSL_KEY" -out "$SSL_CERT"
    
    if [ $? -ne 0 ]; then
        echo "✗ SSL证书生成失败"
        exit 1
    fi
fi

echo "✓ SSL证书生成成功: $SSL_CERT"

# 清理临时文件
rm -f "${SSL_DIR}/nginx.csr"

# 设置文件权限
chmod 600 "$SSL_KEY" 2>/dev/null || echo "⚠ 私钥权限设置失败"
chmod 644 "$SSL_CERT" 2>/dev/null || echo "⚠ 证书权限设置失败"

echo ""
echo "=== 验证SSL证书 ==="

# 验证私钥
echo "验证私钥格式..."
if openssl rsa -in "$SSL_KEY" -check -noout >/dev/null 2>&1; then
    echo "✓ 私钥格式正确"
else
    echo "✗ 私钥格式错误"
    exit 1
fi

# 验证证书
echo "验证证书格式..."
if openssl x509 -in "$SSL_CERT" -text -noout >/dev/null 2>&1; then
    echo "✓ 证书格式正确"
else
    echo "✗ 证书格式错误"
    exit 1
fi

# 显示证书信息
echo ""
echo "=== 证书信息 ==="
echo "证书主题:"
openssl x509 -in "$SSL_CERT" -subject -noout

echo "证书有效期:"
openssl x509 -in "$SSL_CERT" -dates -noout

if [ "$USE_SAN" = true ]; then
    echo "SAN扩展信息:"
    openssl x509 -in "$SSL_CERT" -noout -text | grep -A 10 "Subject Alternative Name" || echo "  SAN扩展读取失败"
fi

echo "证书指纹:"
openssl x509 -in "$SSL_CERT" -fingerprint -noout

echo ""
echo "=== SSL证书初始化完成 ==="
echo "✓ 私钥文件: $SSL_KEY"
echo "✓ 证书文件: $SSL_CERT"
echo "✓ 证书有效期: $SSL_DAYS 天"

if [ "$USE_SAN" = true ]; then
    echo "✓ 证书类型: SAN扩展证书"
    echo ""
    echo "支持的域名和IP:"
    echo "  - localhost"
    echo "  - $SSL_COMMON_NAME"
    echo "  - nginx.local"
    echo "  - api.local"
    echo "  - ssl.local"
    echo "  - 127.0.0.1"
    echo "  - ::1"
    echo ""
    echo "注意事项:"
    echo "- 这是自签名证书，浏览器会显示安全警告"
    echo "- 生产环境请使用正式CA签发的证书"
    echo "- 证书包含SAN扩展，支持多种访问方式"
else
    echo "✓ 证书类型: 标准证书"
    echo ""
    echo "注意事项:"
    echo "- 这是自签名证书，浏览器会显示安全警告"
    echo "- 生产环境请使用正式CA签发的证书"
    echo "- 证书仅对 $SSL_COMMON_NAME 有效"
fi
echo ""
echo "下一步:"
echo "1. 配置nginx使用SSL证书"
echo "2. 重启nginx服务"
echo "3. 测试HTTPS连接"