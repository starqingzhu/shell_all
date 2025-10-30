#!/bin/bash

# Nginx启动脚本 - 简化版
# 专注于启动功能

# 获取脚本所在目录
SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)

# 加载公共配置
source "${SCRIPT_PATH}/nginx_config.sh"

echo "=== 启动 Nginx ==="

# 检查nginx是否已经在运行
if [ -f "$NGINX_PID" ] && [ -s "$NGINX_PID" ]; then
    PID=$(cat $NGINX_PID)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✓ Nginx已在运行 (PID: $PID)"
        exit 0
    else
        # 清理僵尸PID文件
        rm -f $NGINX_PID
    fi
fi

# 检查nginx可执行文件
if [ ! -f "$NGINX_BIN" ]; then
    echo "✗ nginx可执行文件不存在: $NGINX_BIN"
    echo "请先运行 ./install.sh 安装nginx"
    exit 1
fi

# 检查配置文件
if [ ! -f "$NGINX_CONF" ]; then
    echo "✗ 配置文件不存在: $NGINX_CONF"
    exit 1
fi

# 测试配置语法
if ! $NGINX_BIN -t -c $NGINX_CONF >/dev/null 2>&1; then
    echo "✗ 配置文件语法错误"
    $NGINX_BIN -t -c $NGINX_CONF
    exit 1
fi

# 启动nginx
$NGINX_BIN -c $NGINX_CONF

# 验证启动结果
if [ $? -eq 0 ]; then
    sleep 1
    if [ -f "$NGINX_PID" ] && [ -s "$NGINX_PID" ]; then
        PID=$(cat $NGINX_PID)
        if ps -p $PID > /dev/null 2>&1; then
            echo "✓ Nginx启动成功 (PID: $PID)"
        else
            echo "✗ Nginx启动后进程异常退出"
            exit 1
        fi
    else
        echo "✗ Nginx启动失败"
        exit 1
    fi
else
    echo "✗ Nginx启动失败"
    exit 1
fi