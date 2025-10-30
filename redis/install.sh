#! /bin/sh

# 设置错误处理：任何命令失败都会退出脚本
set -e

# 定义变量
REDIS_VERSION="7.2.11"
SCRIPT_DIR=$(pwd)
BIN_DIR="$SCRIPT_DIR"  # Redis 会在这个目录下创建 bin/ 子目录
DATA_DIR="$SCRIPT_DIR/data"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
CONF_DIR="$SCRIPT_DIR/conf"
TARBALL="${REDIS_VERSION}.tar.gz"
SOURCE_DIR="redis-${REDIS_VERSION}"

echo "开始安装 Redis ${REDIS_VERSION}..."
echo "安装目录: $BIN_DIR"

# 创建必要目录
# data 数据存储目录
# scripts 存放脚本目录  
# conf 配置文件目录
# bin 目录会由 Redis 安装过程自动创建
echo "创建目录结构..."
mkdir -p "$DATA_DIR" "$SCRIPTS_DIR" "$CONF_DIR"

# 检查并下载 Redis 源码包
if [ -f "$TARBALL" ]; then
    echo "✓ 发现本地安装包: $TARBALL，跳过下载"
else
    echo "下载 Redis 源码包..."
    wget https://github.com/redis/redis/archive/refs/tags/${REDIS_VERSION}.tar.gz
fi

# 检查并解压源码包
if [ -d "$SOURCE_DIR" ]; then
    echo "✓ 发现已解压的源码目录: $SOURCE_DIR，跳过解压"
else
    echo "解压源码包..."
    tar -zxvf "$TARBALL"
fi

cd "$SOURCE_DIR"

echo "开始编译 Redis..."
make

# 跳过测试以避免TCL依赖问题
echo "⚠️  跳过测试 (避免TCL依赖问题，不影响Redis正常使用)"
# make test

echo "安装 Redis 到 $BIN_DIR..."
# 安装到脚本目录的 bin 目录 (从 redis-7.2.11 目录回到脚本目录再进入 bin)
make PREFIX="$BIN_DIR" install

echo "复制官方配置文件..."
# 复制源码中的官方 redis.conf 到 conf 目录
if [ -f "redis.conf" ]; then
    cp "redis.conf" "$CONF_DIR/redis.conf"
    echo "✓ 已复制官方配置文件到: $CONF_DIR/redis.conf"
    echo "源文件: $(pwd)/redis.conf"
else
    echo "⚠️  未找到源码中的 redis.conf，当前目录: $(pwd)"
    echo "⚠️  将在首次启动时创建基本配置"
fi

echo "返回脚本目录..."
cd "$SCRIPT_DIR"

# # 清理临时文件
# echo "清理临时文件..."
# # 可选择保留安装包以便下次使用
# read -p "是否删除下载的安装包 $TARBALL? [y/N]: " -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#     rm -f "$TARBALL"
#     rm -rf "$SOURCE_DIR"
#     echo "已删除安装包: $TARBALL"
# else
#     echo "保留安装包: $TARBALL (下次安装时可重复使用)"
# fi

echo "验证安装结果..."
if [ -f "$BIN_DIR/bin/redis-server" ] && [ -f "$BIN_DIR/bin/redis-cli" ]; then
    echo "✓ Redis 安装成功！"
    echo "Redis 服务器: $BIN_DIR/bin/redis-server"
    echo "Redis 客户端: $BIN_DIR/bin/redis-cli"
    echo "版本信息："
    "$BIN_DIR/bin/redis-server" --version
    
    echo ""
    echo "🔧 下一步操作："
    echo "1. 配置Redis: ./scripts/configure.sh"
    echo "2. 启动Redis: ./scripts/start.sh"
    echo "3. 检查状态: ./scripts/status.sh"
else
    echo "✗ Redis 安装失败，请检查错误信息"
    exit 1
fi

echo "安装完成！"