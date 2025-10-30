#!/bin/bash

# nginx.conf路径修正脚本
# 功能：自动修正nginx.conf中的路径为当前服务器目录路径

# 获取脚本所在目录并确定nginx根目录
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
NGINX_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)

# 源配置文件和备份配置文件路径
NGINX_CONF="${NGINX_ROOT}/conf/nginx.conf"
NGINX_CONF_BACKUP="${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"

echo "=== Nginx配置路径修正脚本 ==="
echo "nginx根目录: ${NGINX_ROOT}"
echo "配置文件: ${NGINX_CONF}"
echo ""

# 检查nginx.conf文件是否存在
if [ ! -f "${NGINX_CONF}" ]; then
    echo "✗ nginx配置文件不存在: ${NGINX_CONF}"
    echo "请确认nginx已正确安装"
    exit 1
fi

echo "✓ 找到nginx配置文件"

# 备份原配置文件
echo "备份原配置文件到: ${NGINX_CONF_BACKUP}"
cp "${NGINX_CONF}" "${NGINX_CONF_BACKUP}"

if [ $? -ne 0 ]; then
    echo "✗ 配置文件备份失败"
    exit 1
fi

echo "✓ 配置文件备份成功"

# 显示当前配置中的路径
echo ""
echo "=== 当前配置中的路径 ==="
echo "检查现有路径配置..."

# 检查文档根目录路径
if grep -q "root.*html" "${NGINX_CONF}"; then
    echo "发现文档根目录路径:"
    grep "root.*html" "${NGINX_CONF}" | head -3 | sed 's/^/  /'
fi

# 检查日志路径
if grep -q -E "(access_log|error_log).*logs/" "${NGINX_CONF}"; then
    echo "发现日志路径:"
    grep -E "(access_log|error_log).*logs/" "${NGINX_CONF}" | head -5 | sed 's/^/  /'
fi

# 检查SSL证书路径
if grep -q "ssl_certificate.*ssl/" "${NGINX_CONF}"; then
    echo "发现SSL证书路径:"
    grep "ssl_certificate.*ssl/" "${NGINX_CONF}" | head -3 | sed 's/^/  /'
fi

# 检查临时目录路径
if grep -q "temp_path.*temp/" "${NGINX_CONF}"; then
    echo "发现临时目录路径:"
    grep "temp_path.*temp/" "${NGINX_CONF}" | head -3 | sed 's/^/  /'
fi

# 检查PID文件路径
if grep -q "pid.*nginx\.pid" "${NGINX_CONF}"; then
    echo "发现PID文件路径:"
    grep "pid.*nginx\.pid" "${NGINX_CONF}" | head -1 | sed 's/^/  /'
fi

# 检查包含文件路径
if grep -q "include.*\." "${NGINX_CONF}"; then
    echo "发现包含文件路径:"
    grep "include.*\." "${NGINX_CONF}" | head -3 | sed 's/^/  /'
fi

# 确认是否继续
echo ""
read -p "是否继续修正路径配置? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "操作已取消"
    exit 0
fi

echo ""
echo "=== 开始修正路径配置 ==="

# 创建临时配置文件
TEMP_CONF="/tmp/nginx_conf_temp_$$"

# 路径修正函数
fix_paths() {
    sed \
        -e "s|root\s\+[^;]*html[^;]*;|root ${NGINX_ROOT}/html;|g" \
        -e "s|access_log\s\+[^;]*logs/access\.log[^;]*;|access_log ${NGINX_ROOT}/logs/access.log main;|g" \
        -e "s|access_log\s\+[^;]*logs/host\.access\.log[^;]*;|access_log ${NGINX_ROOT}/logs/host.access.log main;|g" \
        -e "s|access_log\s\+[^;]*logs/https_host\.access\.log[^;]*;|access_log ${NGINX_ROOT}/logs/https_host.access.log main;|g" \
        -e "s|access_log\s\+[^;]*logs/api_proxy\.log[^;]*;|access_log ${NGINX_ROOT}/logs/api_proxy.log proxy;|g" \
        -e "s|access_log\s\+[^;]*logs/https_api_proxy\.log[^;]*;|access_log ${NGINX_ROOT}/logs/https_api_proxy.log proxy;|g" \
        -e "s|error_log\s\+[^;]*logs/error\.log[^;]*;|error_log ${NGINX_ROOT}/logs/error.log warn;|g" \
        -e "s|pid\s\+[^;]*logs/nginx\.pid[^;]*;|pid ${NGINX_ROOT}/run/nginx.pid;|g" \
        -e "s|client_body_temp_path\s\+[^;]*temp/client_body_temp[^;]*;|client_body_temp_path ${NGINX_ROOT}/temp/client_body_temp;|g" \
        -e "s|proxy_temp_path\s\+[^;]*temp/proxy_temp[^;]*;|proxy_temp_path ${NGINX_ROOT}/temp/proxy_temp;|g" \
        -e "s|fastcgi_temp_path\s\+[^;]*temp/fastcgi_temp[^;]*;|fastcgi_temp_path ${NGINX_ROOT}/temp/fastcgi_temp;|g" \
        -e "s|uwsgi_temp_path\s\+[^;]*temp/uwsgi_temp[^;]*;|uwsgi_temp_path ${NGINX_ROOT}/temp/uwsgi_temp;|g" \
        -e "s|scgi_temp_path\s\+[^;]*temp/scgi_temp[^;]*;|scgi_temp_path ${NGINX_ROOT}/temp/scgi_temp;|g" \
        -e "s|ssl_certificate\s\+[^;]*ssl/nginx\.crt[^;]*;|ssl_certificate ${NGINX_ROOT}/ssl/nginx.crt;|g" \
        -e "s|ssl_certificate_key\s\+[^;]*ssl/nginx\.key[^;]*;|ssl_certificate_key ${NGINX_ROOT}/ssl/nginx.key;|g" \
        -e "s|include\s\+[^;]*mime\.types[^;]*;|include ${NGINX_ROOT}/conf/mime.types;|g" \
        -e "s|include\s\+[^;]*fastcgi_params[^;]*;|include ${NGINX_ROOT}/conf/fastcgi_params;|g" \
        -e "s|include\s\+[^;]*uwsgi_params[^;]*;|include ${NGINX_ROOT}/conf/uwsgi_params;|g" \
        -e "s|include\s\+[^;]*scgi_params[^;]*;|include ${NGINX_ROOT}/conf/scgi_params;|g" \
        "${NGINX_CONF}" > "${TEMP_CONF}"
}

# 执行路径修正
echo "1. 修正文档根目录路径..."
fix_paths

if [ $? -ne 0 ]; then
    echo "✗ 路径修正失败"
    rm -f "${TEMP_CONF}"
    exit 1
fi

echo "✓ 路径修正完成"

# 验证修正后的配置
echo ""
echo "2. 验证修正后的配置..."

# 检查配置语法
"${NGINX_ROOT}/bin/nginx" -t -c "${TEMP_CONF}" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ 配置语法验证通过"
else
    echo "⚠ 配置语法验证失败，但这可能是由于缺少SSL证书等其他原因"
    echo "继续应用配置..."
fi

# 应用新配置
echo ""
echo "3. 应用新配置..."
mv "${TEMP_CONF}" "${NGINX_CONF}"

if [ $? -ne 0 ]; then
    echo "✗ 配置应用失败"
    echo "恢复备份配置..."
    cp "${NGINX_CONF_BACKUP}" "${NGINX_CONF}"
    exit 1
fi

echo "✓ 新配置已应用"

# 确保必要目录存在
echo ""
echo "4. 创建必要目录..."

# 创建html目录
if [ ! -d "${NGINX_ROOT}/html" ]; then
    mkdir -p "${NGINX_ROOT}/html"
    echo "✓ 创建html目录: ${NGINX_ROOT}/html"
    
    # 创建默认index.html
    cat > "${NGINX_ROOT}/html/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to nginx!</title>
    <style>
        body { width: 35em; margin: 0 auto; font-family: Tahoma, Verdana, Arial, sans-serif; }
    </style>
</head>
<body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and working.</p>
    <p>For online documentation and support please refer to <a href="http://nginx.org/">nginx.org</a>.</p>
    <p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOF
    echo "✓ 创建默认首页: ${NGINX_ROOT}/html/index.html"
fi

# 创建日志目录
if [ ! -d "${NGINX_ROOT}/logs" ]; then
    mkdir -p "${NGINX_ROOT}/logs"
    echo "✓ 创建日志目录: ${NGINX_ROOT}/logs"
fi

# 显示修正后的配置
echo ""
echo "=== 修正后的配置预览 ==="
echo "主要路径配置:"

echo ""
echo "文档根目录:"
grep "root.*html" "${NGINX_CONF}" | sed 's/^/  /'

echo ""
echo "日志文件:"
grep -E "(access_log|error_log).*logs/" "${NGINX_CONF}" | sed 's/^/  /'

echo ""
echo "SSL证书:"
grep "ssl_certificate.*ssl/" "${NGINX_CONF}" | sed 's/^/  /'

echo ""
echo "临时目录:"
grep "temp_path.*temp/" "${NGINX_CONF}" | sed 's/^/  /'

echo ""
echo "PID文件:"
grep "pid.*nginx\.pid" "${NGINX_CONF}" | sed 's/^/  /'

echo ""
echo "包含文件:"
grep "include.*conf/" "${NGINX_CONF}" | sed 's/^/  /'

# 最终验证
echo ""
echo "=== 最终验证 ==="

# 再次检查配置语法
echo "检查nginx配置语法..."
if "${NGINX_ROOT}/bin/nginx" -t -c "${NGINX_CONF}" 2>/dev/null; then
    echo "✓ nginx配置语法正确"
    CONFIG_OK=true
else
    echo "⚠ nginx配置语法检查有警告"
    echo "详细错误信息:"
    "${NGINX_ROOT}/bin/nginx" -t -c "${NGINX_CONF}" 2>&1 | sed 's/^/    /'
    CONFIG_OK=false
fi

# 检查关键文件
echo ""
echo "检查关键文件..."

REQUIRED_FILES=(
    "${NGINX_ROOT}/conf/mime.types"
    "${NGINX_ROOT}/html/index.html"
)

ALL_FILES_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file (缺失)"
        ALL_FILES_OK=false
    fi
done

echo ""
echo "================================================="
echo "nginx.conf路径修正完成！"
echo "================================================="
echo ""
echo "修正信息:"
echo "  nginx根目录: ${NGINX_ROOT}"
echo "  配置文件: ${NGINX_CONF}"
echo "  备份文件: ${NGINX_CONF_BACKUP}"
echo "  文档根目录: ${NGINX_ROOT}/html"
echo "  日志目录: ${NGINX_ROOT}/logs"
echo ""

if [ "$CONFIG_OK" = true ] && [ "$ALL_FILES_OK" = true ]; then
    echo "✓ 所有检查通过，nginx配置已就绪"
    echo ""
    echo "下一步操作:"
    echo "1. 重载nginx配置: cd ../.. && ./scripts/reload.sh"
    echo "2. 重启nginx服务: cd ../.. && ./scripts/restart.sh"
    echo "3. 测试访问: curl http://localhost:8081"
else
    echo "⚠ 存在一些问题，但基本配置已完成"
    echo ""
    echo "建议操作:"
    echo "1. 检查缺失的文件"
    echo "2. 手动验证配置: ${NGINX_ROOT}/bin/nginx -t"
    echo "3. 查看详细错误: ${NGINX_ROOT}/bin/nginx -t -c ${NGINX_CONF}"
fi

echo ""
echo "配置文件管理:"
echo "  查看当前配置: cat ${NGINX_CONF}"
echo "  恢复备份配置: cp ${NGINX_CONF_BACKUP} ${NGINX_CONF}"
echo "  重新运行脚本: ${SCRIPT_DIR}/$(basename $0)"
echo ""
echo "路径修正脚本执行完成！"