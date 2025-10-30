#!/bin/bash

# SSL证书管理脚本
# 管理SSL证书的查看、验证、更新等操作

# 获取脚本所在目录并加载SSL配置
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "${SCRIPT_DIR}/ssl_config.sh"

# 显示帮助信息
show_help() {
    echo "SSL证书管理脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  check     检查SSL证书状态"
    echo "  info      显示证书详细信息"
    echo "  verify    验证证书和私钥匹配"
    echo "  renew     重新生成证书"
    echo "  backup    备份现有证书"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 check    # 检查证书状态"
    echo "  $0 info     # 显示证书信息"
    echo "  $0 renew    # 重新生成证书"
}

# 检查SSL证书状态
check_ssl_status() {
    echo "=== SSL证书状态检查 ==="
    
    if ! check_openssl; then
        return 1
    fi
    
    local errors=0
    
    # 检查目录
    if [ -d "$SSL_DIR" ]; then
        echo "✓ SSL目录存在: $SSL_DIR"
    else
        echo "✗ SSL目录不存在: $SSL_DIR"
        errors=$((errors + 1))
    fi
    
    # 检查私钥
    if [ -f "$SSL_KEY" ]; then
        echo "✓ 私钥文件存在: $SSL_KEY"
        
        # 验证私钥格式
        if openssl rsa -in "$SSL_KEY" -check -noout >/dev/null 2>&1; then
            echo "✓ 私钥格式正确"
        else
            echo "✗ 私钥格式错误"
            errors=$((errors + 1))
        fi
    else
        echo "✗ 私钥文件不存在: $SSL_KEY"
        errors=$((errors + 1))
    fi
    
    # 检查证书
    if [ -f "$SSL_CERT" ]; then
        echo "✓ 证书文件存在: $SSL_CERT"
        
        # 验证证书格式
        if openssl x509 -in "$SSL_CERT" -text -noout >/dev/null 2>&1; then
            echo "✓ 证书格式正确"
            
            # 检查证书是否过期
            if openssl x509 -in "$SSL_CERT" -checkend 0 >/dev/null 2>&1; then
                echo "✓ 证书仍然有效"
            else
                echo "⚠ 证书已过期"
                errors=$((errors + 1))
            fi
            
            # 检查即将过期（30天内）
            if openssl x509 -in "$SSL_CERT" -checkend 2592000 >/dev/null 2>&1; then
                echo "✓ 证书在30天内不会过期"
            else
                echo "⚠ 证书将在30天内过期"
            fi
        else
            echo "✗ 证书格式错误"
            errors=$((errors + 1))
        fi
    else
        echo "✗ 证书文件不存在: $SSL_CERT"
        errors=$((errors + 1))
    fi
    
    echo ""
    if [ $errors -eq 0 ]; then
        echo "✓ SSL证书状态正常"
        return 0
    else
        echo "✗ SSL证书存在 $errors 个问题"
        return 1
    fi
}

# 显示证书详细信息
show_ssl_info() {
    echo "=== SSL证书详细信息 ==="
    
    if [ ! -f "$SSL_CERT" ]; then
        echo "✗ 证书文件不存在: $SSL_CERT"
        return 1
    fi
    
    echo ""
    echo "证书文件: $SSL_CERT"
    echo "私钥文件: $SSL_KEY"
    echo ""
    
    echo "证书主题:"
    openssl x509 -in "$SSL_CERT" -subject -noout
    
    echo ""
    echo "证书颁发者:"
    openssl x509 -in "$SSL_CERT" -issuer -noout
    
    echo ""
    echo "证书有效期:"
    openssl x509 -in "$SSL_CERT" -dates -noout
    
    echo ""
    echo "证书序列号:"
    openssl x509 -in "$SSL_CERT" -serial -noout
    
    echo ""
    echo "证书SHA1指纹:"
    openssl x509 -in "$SSL_CERT" -fingerprint -sha1 -noout
    
    echo ""
    echo "证书SHA256指纹:"
    openssl x509 -in "$SSL_CERT" -fingerprint -sha256 -noout
    
    echo ""
    echo "证书公钥信息:"
    openssl x509 -in "$SSL_CERT" -pubkey -noout | openssl rsa -pubin -text -noout 2>/dev/null | head -5
}

# 验证证书和私钥匹配
verify_ssl_match() {
    echo "=== 验证证书和私钥匹配 ==="
    
    if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
        echo "✗ 证书或私钥文件不存在"
        return 1
    fi
    
    # 获取证书公钥哈希
    CERT_HASH=$(openssl x509 -in "$SSL_CERT" -pubkey -noout | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1)
    
    # 获取私钥公钥哈希
    KEY_HASH=$(openssl rsa -in "$SSL_KEY" -pubout -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1)
    
    if [ "$CERT_HASH" = "$KEY_HASH" ]; then
        echo "✓ 证书和私钥匹配"
        return 0
    else
        echo "✗ 证书和私钥不匹配"
        echo "证书公钥哈希: $CERT_HASH"
        echo "私钥公钥哈希: $KEY_HASH"
        return 1
    fi
}

# 重新生成证书
renew_ssl() {
    echo "=== 重新生成SSL证书 ==="
    echo "这将重新生成SSL证书和私钥"
    echo ""
    
    read -p "确认重新生成SSL证书? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "操作已取消"
        return 0
    fi
    
    # 调用初始化脚本
    "${SCRIPT_DIR}/init_ssl.sh"
}

# 备份SSL证书
backup_ssl() {
    echo "=== 备份SSL证书 ==="
    
    if [ ! -f "$SSL_CERT" ] && [ ! -f "$SSL_KEY" ]; then
        echo "✗ 没有SSL证书文件需要备份"
        return 1
    fi
    
    backup_ssl_certificates
    echo "✓ SSL证书备份完成"
}

# 主程序
case "${1:-help}" in
    "check")
        check_ssl_status
        ;;
    "info")
        show_ssl_info
        ;;
    "verify")
        verify_ssl_match
        ;;
    "renew")
        renew_ssl
        ;;
    "backup")
        backup_ssl
        ;;
    "help"|*)
        show_help
        ;;
esac