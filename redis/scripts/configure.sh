#!/bin/bash
# Redis 配置脚本 - 用于修改Redis配置文件

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(dirname "$SCRIPT_DIR")
CONF_DIR="$BASE_DIR/conf"
DATA_DIR="$BASE_DIR/data"
REDIS_CONF="$CONF_DIR/redis.conf"

echo "开始配置 Redis..."

# 检查配置文件是否存在
if [ ! -f "$REDIS_CONF" ]; then
    echo "✗ Redis 配置文件不存在: $REDIS_CONF"
    echo "请先运行 install.sh 安装 Redis"
    exit 1
fi

echo "配置文件路径: $REDIS_CONF"

# 备份原始配置文件
if [ ! -f "$REDIS_CONF.original" ]; then
    cp "$REDIS_CONF" "$REDIS_CONF.original"
    echo "✓ 已备份原始配置文件"
fi

echo "调整配置文件路径和设置..."

# 1. 设置pidfile路径 (使用绝对路径更可靠)
if grep -q "^pidfile" "$REDIS_CONF"; then
    sed -i 's|^pidfile.*|pidfile '"$DATA_DIR"'/redis.pid|' "$REDIS_CONF"
elif grep -q "^# pidfile" "$REDIS_CONF"; then
    sed -i 's|^# pidfile.*|pidfile '"$DATA_DIR"'/redis.pid|' "$REDIS_CONF"
else
    echo "pidfile $DATA_DIR/redis.pid" >> "$REDIS_CONF"
fi

# 2. 设置logfile路径 (使用绝对路径更可靠)
if grep -q "^logfile" "$REDIS_CONF"; then
    sed -i 's|^logfile.*|logfile '"$DATA_DIR"'/redis.log|' "$REDIS_CONF"
elif grep -q "^# logfile" "$REDIS_CONF"; then
    sed -i 's|^# logfile.*|logfile '"$DATA_DIR"'/redis.log|' "$REDIS_CONF"
else
    echo "logfile $DATA_DIR/redis.log" >> "$REDIS_CONF"
fi

# 3. 设置工作目录 (使用绝对路径)
if grep -q "^dir" "$REDIS_CONF"; then
    sed -i 's|^dir.*|dir '"$DATA_DIR"'/|' "$REDIS_CONF"
elif grep -q "^# dir" "$REDIS_CONF"; then
    sed -i 's|^# dir.*|dir '"$DATA_DIR"'/|' "$REDIS_CONF"
else
    echo "dir $DATA_DIR/" >> "$REDIS_CONF"
fi

# 4. 确保后台运行
if grep -q "^daemonize" "$REDIS_CONF"; then
    sed -i 's|^daemonize.*|daemonize yes|' "$REDIS_CONF"
elif grep -q "^# daemonize" "$REDIS_CONF"; then
    sed -i 's|^# daemonize.*|daemonize yes|' "$REDIS_CONF"
else
    echo "daemonize yes" >> "$REDIS_CONF"
fi

# 5. 设置网络访问 - 允许任何机器访问
if grep -q "^bind" "$REDIS_CONF"; then
    sed -i 's|^bind.*|bind 0.0.0.0|' "$REDIS_CONF"
elif grep -q "^# bind" "$REDIS_CONF"; then
    sed -i 's|^# bind.*|bind 0.0.0.0|' "$REDIS_CONF"
else
    echo "bind 0.0.0.0" >> "$REDIS_CONF"
fi

# 6. 关闭保护模式 (允许远程连接)
if grep -q "^protected-mode" "$REDIS_CONF"; then
    sed -i 's|^protected-mode.*|protected-mode no|' "$REDIS_CONF"
elif grep -q "^# protected-mode" "$REDIS_CONF"; then
    sed -i 's|^# protected-mode.*|protected-mode no|' "$REDIS_CONF"
else
    echo "protected-mode no" >> "$REDIS_CONF"
fi

# # 7. 设置密码保护 (推荐！)
# REDIS_PASSWORD="123456"
# if grep -q "^requirepass" "$REDIS_CONF"; then
#     sed -i 's|^requirepass.*|requirepass '"$REDIS_PASSWORD"'|' "$REDIS_CONF"
# elif grep -q "^# requirepass" "$REDIS_CONF"; then
#     sed -i 's|^# requirepass.*|requirepass '"$REDIS_PASSWORD"'|' "$REDIS_CONF"
# else
#     echo "requirepass $REDIS_PASSWORD" >> "$REDIS_CONF"
# fi

# 8. 配置AOF持久化 (更安全的持久化方式)
echo "配置 AOF 持久化..."

# 启用AOF
if grep -q "^appendonly" "$REDIS_CONF"; then
    sed -i 's|^appendonly.*|appendonly yes|' "$REDIS_CONF"
elif grep -q "^# appendonly" "$REDIS_CONF"; then
    sed -i 's|^# appendonly.*|appendonly yes|' "$REDIS_CONF"
else
    echo "appendonly yes" >> "$REDIS_CONF"
fi

# 设置AOF文件名
if grep -q "^appendfilename" "$REDIS_CONF"; then
    sed -i 's|^appendfilename.*|appendfilename "appendonly.aof"|' "$REDIS_CONF"
elif grep -q "^# appendfilename" "$REDIS_CONF"; then
    sed -i 's|^# appendfilename.*|appendfilename "appendonly.aof"|' "$REDIS_CONF"
else
    echo 'appendfilename "appendonly.aof"' >> "$REDIS_CONF"
fi

# 设置AOF同步策略 (每秒同步，平衡性能和安全)
if grep -q "^appendfsync" "$REDIS_CONF"; then
    sed -i 's|^appendfsync.*|appendfsync everysec|' "$REDIS_CONF"
elif grep -q "^# appendfsync" "$REDIS_CONF"; then
    sed -i 's|^# appendfsync.*|appendfsync everysec|' "$REDIS_CONF"
else
    echo "appendfsync everysec" >> "$REDIS_CONF"
fi

# 关闭RDB快照 (使用AOF替代)
if grep -q "^save " "$REDIS_CONF"; then
    sed -i 's|^save .*|# save disabled - using AOF instead|' "$REDIS_CONF"
fi
# 添加一个明确的save ""来关闭RDB
if ! grep -q "^save \"\"" "$REDIS_CONF"; then
    echo 'save ""' >> "$REDIS_CONF"
fi

echo ""
echo "✓ Redis 配置完成！"
echo "⚠️  Redis密码已设置为: $REDIS_PASSWORD"
echo "⚠️  请记录此密码，连接时需要使用！"
echo "✓ AOF持久化已启用，数据文件: $DATA_DIR/appendonly.aof"
echo "✓ 网络访问: 0.0.0.0 (允许远程连接)"
echo "✓ 配置文件: $REDIS_CONF"
echo "✓ 原始配置备份: $REDIS_CONF.original"
echo ""
echo "现在可以使用以下命令启动Redis:"
echo "  ./scripts/start.sh"