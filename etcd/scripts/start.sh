#!/bin/bash

# etcd启动脚本
# 作者: sunbin
# 日期: 2025-10-28

# 设置变量
ETCD_NAME=${ETCD_NAME:-"MH"}
ETCD_DATA_DIR=${ETCD_DATA_DIR:-"$(pwd)/../data"}
ETCD_LISTEN_PEER_URLS=${ETCD_LISTEN_PEER_URLS:-"http://0.0.0.0:2380"}
ETCD_LISTEN_CLIENT_URLS=${ETCD_LISTEN_CLIENT_URLS:-"http://0.0.0.0:2379"}
ETCD_INITIAL_ADVERTISE_PEER_URLS=${ETCD_INITIAL_ADVERTISE_PEER_URLS:-"http://0.0.0.0:2380"}
ETCD_ADVERTISE_CLIENT_URLS=${ETCD_ADVERTISE_CLIENT_URLS:-"http://0.0.0.0:2379"}
# 确保节点名称与初始集群配置匹配
ETCD_INITIAL_CLUSTER=${ETCD_INITIAL_CLUSTER:-"${ETCD_NAME}=http://0.0.0.0:2380"}
ETCD_INITIAL_CLUSTER_STATE=${ETCD_INITIAL_CLUSTER_STATE:-"new"}
ETCD_INITIAL_CLUSTER_TOKEN=${ETCD_INITIAL_CLUSTER_TOKEN:-"etcd-cluster"}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查etcd二进制文件是否存在
check_etcd_binary() {
    if [ ! -f "../bin/etcd" ]; then
        log_error "etcd binary not found in ../bin/etcd"
        log_info "Please run install.sh first to install etcd"
        exit 1
    fi
}

# 检查数据目录
check_data_dir() {
    if [ ! -d "$ETCD_DATA_DIR" ]; then
        log_info "Creating data directory: $ETCD_DATA_DIR"
        mkdir -p "$ETCD_DATA_DIR"
    fi
    
    # 修复数据目录权限（etcd建议使用700权限）
    current_perm=$(stat -c "%a" "$ETCD_DATA_DIR" 2>/dev/null || echo "unknown")
    if [ "$current_perm" != "700" ]; then
        log_info "Setting recommended permissions (700) for data directory"
        chmod 700 "$ETCD_DATA_DIR"
    fi
}

# 检查配置一致性
check_config_consistency() {
    # 检查节点名称是否在初始集群配置中
    if ! echo "$ETCD_INITIAL_CLUSTER" | grep -q "^$ETCD_NAME=" || ! echo "$ETCD_INITIAL_CLUSTER" | grep -q ",$ETCD_NAME=" || [ "$ETCD_INITIAL_CLUSTER" = "${ETCD_NAME}="* ]; then
        # 如果节点名不在集群配置中，可能是配置错误
        log_warn "Node name '$ETCD_NAME' may not match initial cluster configuration: $ETCD_INITIAL_CLUSTER"
        log_info "This is normal for single-node setup, but check configuration for multi-node clusters"
    fi
}

# 检查是否已经在运行
check_running() {
    # 如果是从重启脚本调用的，跳过运行检查
    if [ "$RESTART_MODE" = "true" ]; then
        log_info "Running in restart mode, skipping running check"
        return 0
    fi
    
    if pgrep -f "etcd" > /dev/null; then
        log_warn "etcd is already running!"
        echo "PID: $(pgrep -f etcd)"
        echo "Use 'scripts/stop.sh' to stop it first, or 'scripts/restart.sh' to restart"
        exit 1
    fi
}

# 启动etcd
start_etcd() {
    log_info "Starting etcd with following configuration:"
    echo "  Name: $ETCD_NAME"
    echo "  Data Dir: $ETCD_DATA_DIR"
    echo "  Client URLs: $ETCD_LISTEN_CLIENT_URLS"
    echo "  Peer URLs: $ETCD_LISTEN_PEER_URLS"
    echo "  Initial Cluster: $ETCD_INITIAL_CLUSTER"
    
    # 启动etcd进程
    nohup ../bin/etcd \
        --name "$ETCD_NAME" \
        --data-dir "$ETCD_DATA_DIR" \
        --listen-peer-urls "$ETCD_LISTEN_PEER_URLS" \
        --listen-client-urls "$ETCD_LISTEN_CLIENT_URLS" \
        --advertise-client-urls "$ETCD_ADVERTISE_CLIENT_URLS" \
        --initial-advertise-peer-urls "$ETCD_INITIAL_ADVERTISE_PEER_URLS" \
        --initial-cluster "$ETCD_INITIAL_CLUSTER" \
        --initial-cluster-state "$ETCD_INITIAL_CLUSTER_STATE" \
        --initial-cluster-token "$ETCD_INITIAL_CLUSTER_TOKEN" \
        --log-level info \
        --logger zap \
        --log-outputs stderr \
        > ../logs/etcd.log 2>&1 &
    
    ETCD_PID=$!
    echo $ETCD_PID > ../etcd.pid
    
    # 等待一下，检查启动是否成功
    sleep 2
    
    if kill -0 $ETCD_PID 2>/dev/null; then
        log_info "etcd started successfully!"
        log_info "PID: $ETCD_PID"
        log_info "Log file: ../logs/etcd.log"
        log_info "Client endpoint: $ETCD_ADVERTISE_CLIENT_URLS"
        
        # 测试连接
        if ../bin/etcdctl --endpoints="$ETCD_ADVERTISE_CLIENT_URLS" endpoint health > /dev/null 2>&1; then
            log_info "etcd health check passed!"
        else
            log_warn "etcd health check failed, but process is running"
        fi
    else
        log_error "Failed to start etcd!"
        if [ -f "../logs/etcd.log" ]; then
            log_error "Check ../logs/etcd.log for details:"
            tail -10 ../logs/etcd.log
        fi
        exit 1
    fi
}

# 主函数
main() {
    log_info "Starting etcd server..."
    
    # 创建日志目录
    mkdir -p ../logs
    
    # 执行检查
    check_etcd_binary
    check_data_dir
    check_config_consistency
    check_running
    
    # 启动etcd
    start_etcd
}

# 执行主函数
main "$@"