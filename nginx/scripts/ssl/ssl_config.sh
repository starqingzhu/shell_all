#!/bin/bash

# SSL公共配置文件
# 读取nginx公共配置，并扩展SSL相关配置

# ===========================================
# 加载nginx公共配置
# ===========================================
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NGINX_SCRIPTS_DIR=$(dirname "$SCRIPT_DIR")

# 加载nginx基础配置
source "${NGINX_SCRIPTS_DIR}/nginx_config.sh"

# ===========================================
# SSL专用配置
# ===========================================
# SSL证书目录
SSL_DIR="${NGINX_HOME}/ssl"

# SSL证书文件路径
SSL_CERT="${SSL_DIR}/nginx.crt"
SSL_KEY="${SSL_DIR}/nginx.key"

# SSL配置参数
SSL_COUNTRY="CN"
SSL_STATE="Beijing"
SSL_CITY="Beijing"
SSL_ORG="Local Development"
SSL_UNIT="IT Department"

# SSL通用名称配置 - 根据使用场景选择：
# 开发/测试环境推荐: localhost
# 生产环境请修改为: 实际域名或公网IP
SSL_COMMON_NAME="localhost"

# SSL邮箱配置 - 根据需要修改：
# 开发/测试环境可保持: admin@localhost
# 生产环境建议修改为: 您的真实邮箱地址
SSL_EMAIL="admin@localhost"

# 如果需要使用公网配置，请取消下面行的注释并修改：
# SSL_COMMON_NAME="your-domain.com"  # 或您的公网IP
# SSL_EMAIL="your-email@example.com"  # 您的真实邮箱

# SSL证书有效期（天数）
SSL_DAYS=365

# SSL密钥长度
SSL_KEY_LENGTH=2048

# ===========================================
# SSL功能函数
# ===========================================

# 检查SSL证书是否存在
check_ssl_certificates() {
    local errors=0
    
    if [ ! -d "$SSL_DIR" ]; then
        echo "✗ SSL证书目录不存在: $SSL_DIR"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "$SSL_CERT" ]; then
        echo "✗ SSL证书文件不存在: $SSL_CERT"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "$SSL_KEY" ]; then
        echo "✗ SSL私钥文件不存在: $SSL_KEY"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# 显示SSL配置信息
show_ssl_config() {
    echo "=== SSL配置信息 ==="
    echo "SSL证书目录: $SSL_DIR"
    echo "SSL证书文件: $SSL_CERT"
    echo "SSL私钥文件: $SSL_KEY"
    echo "证书有效期: $SSL_DAYS 天"
    echo "密钥长度: $SSL_KEY_LENGTH 位"
    echo "通用名称: $SSL_COMMON_NAME"
    echo "==================="
}

# 创建SSL目录
create_ssl_directories() {
    if [ ! -d "$SSL_DIR" ]; then
        mkdir -p "$SSL_DIR"
        echo "✓ 创建SSL目录: $SSL_DIR"
    fi
    
    # 设置目录权限
    chmod 700 "$SSL_DIR" 2>/dev/null || echo "⚠ SSL目录权限设置失败"
}

# 检查OpenSSL工具
check_openssl() {
    if ! command -v openssl >/dev/null 2>&1; then
        echo "✗ OpenSSL工具未找到"
        echo "请安装OpenSSL: sudo yum install -y openssl"
        return 1
    fi
    
    echo "✓ OpenSSL版本: $(openssl version)"
    return 0
}

# 备份现有SSL证书
backup_ssl_certificates() {
    if [ -f "$SSL_CERT" ] || [ -f "$SSL_KEY" ]; then
        local backup_dir="${SSL_DIR}/backup.$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        
        if [ -f "$SSL_CERT" ]; then
            cp "$SSL_CERT" "$backup_dir/"
            echo "✓ 备份证书文件到: $backup_dir/"
        fi
        
        if [ -f "$SSL_KEY" ]; then
            cp "$SSL_KEY" "$backup_dir/"
            echo "✓ 备份私钥文件到: $backup_dir/"
        fi
        
        echo "✓ SSL证书已备份到: $backup_dir"
    fi
}