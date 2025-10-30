#!/bin/bash

# etcd重启脚本
# 作者: Assistant
# 日期: 2025-10-28

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 检查脚本是否存在
check_scripts() {
    if [ ! -f "$SCRIPT_DIR/stop.sh" ]; then
        log_error "stop.sh script not found in $SCRIPT_DIR"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/start.sh" ]; then
        log_error "start.sh script not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # 确保脚本有执行权限
    chmod +x "$SCRIPT_DIR/stop.sh"
    chmod +x "$SCRIPT_DIR/start.sh"
}

# 检查etcd状态
check_etcd_status() {
    if pgrep -f "etcd" > /dev/null; then
        return 0  # 运行中
    else
        return 1  # 未运行
    fi
}

# 等待etcd完全停止
wait_for_stop() {
    local max_wait=${1:-30}
    local count=0
    
    log_info "Waiting for etcd to stop completely..."
    while check_etcd_status && [ $count -lt $max_wait ]; do
        sleep 1
        count=$((count + 1))
        echo -n "."
    done
    echo
    
    if check_etcd_status; then
        return 1  # 仍在运行
    else
        return 0  # 已停止
    fi
}

# 备份数据（可选）
backup_data() {
    local data_dir="$PROJECT_ROOT/data"
    local backup_dir="$PROJECT_ROOT/backup"
    
    if [ -d "$data_dir" ] && [ "$(ls -A "$data_dir" 2>/dev/null)" ]; then
        log_info "Creating data backup..."
        mkdir -p "$backup_dir"
        
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_name="etcd_data_backup_$timestamp"
        
        if cp -r "$data_dir" "$backup_dir/$backup_name"; then
            log_info "Data backed up to: $backup_dir/$backup_name"
            
            # 只保留最近5个备份
            cd "$backup_dir"
            ls -1t etcd_data_backup_* 2>/dev/null | tail -n +6 | xargs rm -rf 2>/dev/null || true
        else
            log_warn "Failed to create backup, continuing without backup..."
        fi
    fi
}

# 主函数
main() {
    local force_mode=false
    local no_backup=false
    local quick_mode=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force_mode=true
                shift
                ;;
            --no-backup)
                no_backup=true
                shift
                ;;
            -q|--quick)
                quick_mode=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -f, --force       Force restart (kill processes if needed)"
                echo "  --no-backup       Skip data backup before restart"
                echo "  -q, --quick       Quick restart (skip health checks)"
                echo "  -h, --help        Show this help message"
                echo ""
                echo "Description:"
                echo "  Restarts the etcd server by stopping and starting it."
                echo "  By default, creates a backup of data before restart."
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    log_info "Restarting etcd server..."
    log_debug "Force mode: $force_mode"
    log_debug "No backup: $no_backup"
    log_debug "Quick mode: $quick_mode"
    
    # 进入项目根目录
    cd "$PROJECT_ROOT" || {
        log_error "Failed to change to project directory: $PROJECT_ROOT"
        exit 1
    }
    
    # 检查所需脚本
    check_scripts
    
    # 检查当前状态
    local was_running=false
    if check_etcd_status; then
        was_running=true
        log_info "etcd is currently running, will stop it first"
        
        # 创建数据备份（除非禁用）
        if [ "$no_backup" = false ]; then
            backup_data
        fi
        
        # 停止etcd
        log_info "Stopping etcd..."
        if [ "$force_mode" = true ]; then
            "$SCRIPT_DIR/stop.sh" --force
        else
            "$SCRIPT_DIR/stop.sh"
        fi
        
        local stop_exit_code=$?
        
        # 等待一下，然后检查是否真的停止了
        sleep 2
        
        # 检查是否还有etcd进程在运行
        if check_etcd_status; then
            log_error "etcd processes are still running after stop attempt"
            if [ "$force_mode" = false ]; then
                log_info "Try using --force option to force restart"
                exit 1
            else
                log_warn "Force killing remaining processes..."
                pkill -KILL -f "etcd" 2>/dev/null || true
                sleep 2
            fi
        else
            log_info "etcd stopped successfully"
        fi
    else
        log_info "etcd is not currently running"
    fi
    
    # 等待一下确保端口释放
    if [ "$quick_mode" = false ]; then
        log_info "Waiting for ports to be released..."
        sleep 3
    fi
    
    # 清理可能存在的僵尸进程和PID文件
    log_info "Cleaning up any remaining processes and PID files..."
    
    # 清理PID文件
    if [ -f "$PROJECT_ROOT/etcd.pid" ]; then
        local old_pid=$(cat "$PROJECT_ROOT/etcd.pid")
        if ! kill -0 "$old_pid" 2>/dev/null; then
            log_info "Removing stale PID file"
            rm -f "$PROJECT_ROOT/etcd.pid"
        fi
    fi
    
    # 强制清理任何残留的etcd进程
    local remaining_pids=$(pgrep -f "etcd" 2>/dev/null || true)
    if [ -n "$remaining_pids" ]; then
        log_warn "Found remaining etcd processes: $remaining_pids"
        log_info "Cleaning up remaining processes..."
        pkill -TERM -f "etcd" 2>/dev/null || true
        sleep 2
        pkill -KILL -f "etcd" 2>/dev/null || true
        sleep 1
    fi
    
    # 启动etcd
    log_info "Starting etcd..."
    # 设置重启模式环境变量，让start.sh跳过运行检查
    # 切换到scripts目录执行start.sh
    cd "$SCRIPT_DIR" && RESTART_MODE=true ./start.sh
    local start_exit_code=$?
    
    # 切换回项目根目录
    cd "$PROJECT_ROOT"
    
    if [ $start_exit_code -eq 0 ]; then
        log_info "etcd restarted successfully!"
        
        # 如果不是快速模式，进行健康检查
        if [ "$quick_mode" = false ]; then
            log_info "Performing health check..."
            sleep 3
            
            if ./bin/etcdctl --endpoints="http://localhost:2379" endpoint health > /dev/null 2>&1; then
                log_info "Health check passed!"
            else
                log_warn "Health check failed, but etcd appears to be running"
                log_info "Check logs/etcd.log for details"
            fi
        fi
        
        # 显示状态信息
        if [ -f "etcd.pid" ]; then
            local pid=$(cat etcd.pid)
            log_info "etcd PID: $pid"
        fi
        
        log_info "Client endpoint: http://localhost:2379"
        log_info "Log file: logs/etcd.log"
        
    else
        log_error "Failed to start etcd (exit code: $start_exit_code)"
        log_error "Check logs/etcd.log for details"
        exit $start_exit_code
    fi
}

# 执行主函数
main "$@"