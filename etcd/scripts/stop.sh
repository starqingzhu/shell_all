#!/bin/bash

# etcd停止脚本
# 作者: Assistant
# 日期: 2025-10-28

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

# 通过PID文件停止
stop_by_pid_file() {
    if [ -f "../etcd.pid" ]; then
        PID=$(cat ../etcd.pid)
        if kill -0 $PID 2>/dev/null; then
            log_info "Stopping etcd process (PID: $PID)..."
            
            # 首先尝试优雅停止 (SIGTERM)
            kill -TERM $PID
            
            # 等待进程退出
            local count=0
            while kill -0 $PID 2>/dev/null && [ $count -lt 30 ]; do
                sleep 1
                count=$((count + 1))
                echo -n "."
            done
            echo
            
            # 检查进程是否已经停止
            if kill -0 $PID 2>/dev/null; then
                log_warn "Process did not stop gracefully, force killing..."
                kill -KILL $PID
                sleep 1
                
                if kill -0 $PID 2>/dev/null; then
                    log_error "Failed to stop etcd process!"
                    return 1
                else
                    log_info "etcd process force killed"
                fi
            else
                log_info "etcd stopped gracefully"
            fi
            
            # 删除PID文件
            rm -f ../etcd.pid
            return 0
        else
            log_warn "PID file exists but process is not running"
            rm -f ../etcd.pid
            return 0
        fi
    else
        return 1
    fi
}

# 通过进程名停止
stop_by_process_name() {
    local pids=$(pgrep -f "etcd")
    if [ -n "$pids" ]; then
        log_info "Found etcd processes: $pids"
        
        for pid in $pids; do
            log_info "Stopping etcd process (PID: $pid)..."
            
            # 首先尝试优雅停止
            kill -TERM $pid
            
            # 等待进程退出
            local count=0
            while kill -0 $pid 2>/dev/null && [ $count -lt 30 ]; do
                sleep 1
                count=$((count + 1))
                echo -n "."
            done
            echo
            
            # 检查进程是否已经停止
            if kill -0 $pid 2>/dev/null; then
                log_warn "Process $pid did not stop gracefully, force killing..."
                kill -KILL $pid
                sleep 1
                
                if kill -0 $pid 2>/dev/null; then
                    log_error "Failed to stop etcd process $pid!"
                else
                    log_info "etcd process $pid force killed"
                fi
            else
                log_info "etcd process $pid stopped gracefully"
            fi
        done
        
        # 清理PID文件
        rm -f ../etcd.pid
        return 0
    else
        return 1
    fi
}

# 检查etcd状态
check_etcd_status() {
    if pgrep -f "etcd" > /dev/null; then
        return 0  # 运行中
    else
        return 1  # 未运行
    fi
}

# 主函数
main() {
    local force_mode=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force_mode=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -f, --force    Force kill etcd processes"
                echo "  -h, --help     Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    log_info "Stopping etcd server..."
    
    # 检查etcd是否在运行
    if ! check_etcd_status; then
        log_warn "etcd is not running"
        # 清理可能存在的PID文件
        if [ -f "../etcd.pid" ]; then
            log_info "Cleaning up stale PID file"
            rm -f ../etcd.pid
        fi
        exit 0
    fi
    
    # 如果是强制模式，直接杀死所有etcd进程
    if [ "$force_mode" = true ]; then
        log_warn "Force mode enabled, killing all etcd processes..."
        pkill -KILL -f "etcd"
        rm -f ../etcd.pid
        log_info "All etcd processes have been force killed"
        exit 0
    fi
    
    # 尝试通过PID文件停止
    local stop_success=false
    if stop_by_pid_file; then
        log_info "etcd stopped successfully via PID file"
        stop_success=true
    else
        # 如果PID文件方法失败，尝试通过进程名停止
        log_info "PID file not found or invalid, trying to stop by process name..."
        if stop_by_process_name; then
            log_info "etcd stopped successfully via process name"
            stop_success=true
        else
            log_error "No etcd processes found to stop"
            exit 1
        fi
    fi
    
    # 最终检查（只在停止操作成功后检查）
    if [ "$stop_success" = true ]; then
        sleep 1
        if check_etcd_status; then
            log_error "Failed to stop etcd completely!"
            log_info "You may need to use --force option or manually kill the processes"
            exit 1
        else
            log_info "All etcd processes have been stopped successfully"
        fi
    fi
}

# 执行主函数
main "$@"