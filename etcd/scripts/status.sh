#!/bin/bash

# etcd状态检查脚本
# 作者: Assistant
# 日期: 2025-10-28

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_status() {
    echo -e "${CYAN}$1${NC}"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 检查进程状态
check_process_status() {
    local pids=$(pgrep -f "etcd")
    
    if [ -n "$pids" ]; then
        echo -e "${GREEN}✓${NC} etcd process is running"
        echo "  Process ID(s): $pids"
        
        # 检查PID文件
        if [ -f "$PROJECT_ROOT/etcd.pid" ]; then
            local pid_file_content=$(cat "$PROJECT_ROOT/etcd.pid")
            if echo "$pids" | grep -q "$pid_file_content"; then
                echo -e "  PID file: ${GREEN}✓${NC} matches running process ($pid_file_content)"
            else
                echo -e "  PID file: ${YELLOW}⚠${NC} exists but doesn't match running process ($pid_file_content)"
            fi
        else
            echo -e "  PID file: ${YELLOW}⚠${NC} not found"
        fi
        
        # 显示进程详细信息
        echo "  Process details:"
        ps aux | grep "[e]tcd" | while read line; do
            echo "    $line"
        done
        
        return 0
    else
        echo -e "${RED}✗${NC} etcd process is not running"
        
        # 检查是否有僵尸PID文件
        if [ -f "$PROJECT_ROOT/etcd.pid" ]; then
            echo -e "  PID file: ${RED}✗${NC} stale PID file found ($(cat "$PROJECT_ROOT/etcd.pid"))"
        fi
        
        return 1
    fi
}

# 检查端口状态
check_port_status() {
    local client_port=2379
    local peer_port=2380
    
    echo -e "\n${CYAN}Port Status:${NC}"
    
    # 检查客户端端口
    if netstat -tln 2>/dev/null | grep -q ":$client_port "; then
        echo -e "  Client port ($client_port): ${GREEN}✓${NC} listening"
    else
        echo -e "  Client port ($client_port): ${RED}✗${NC} not listening"
    fi
    
    # 检查节点间通信端口
    if netstat -tln 2>/dev/null | grep -q ":$peer_port "; then
        echo -e "  Peer port ($peer_port): ${GREEN}✓${NC} listening"
    else
        echo -e "  Peer port ($peer_port): ${RED}✗${NC} not listening"
    fi
}

# 检查etcd健康状态
check_etcd_health() {
    echo -e "\n${CYAN}Health Check:${NC}"
    
    if [ ! -f "$PROJECT_ROOT/bin/etcdctl" ]; then
        echo -e "  ${YELLOW}⚠${NC} etcdctl not found, skipping health check"
        return 1
    fi
    
    local endpoint="http://localhost:2379"
    
    # 端点健康检查
    if timeout 5 "$PROJECT_ROOT/bin/etcdctl" --endpoints="$endpoint" endpoint health > /dev/null 2>&1; then
        echo -e "  Endpoint health: ${GREEN}✓${NC} healthy"
    else
        echo -e "  Endpoint health: ${RED}✗${NC} unhealthy or unreachable"
        return 1
    fi
    
    # 获取集群成员信息
    local member_info
    member_info=$(timeout 5 "$PROJECT_ROOT/bin/etcdctl" --endpoints="$endpoint" member list 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "  Cluster members: ${GREEN}✓${NC} accessible"
        echo "$member_info" | while read line; do
            echo "    $line"
        done
    else
        echo -e "  Cluster members: ${YELLOW}⚠${NC} unable to retrieve member list"
    fi
    
    return 0
}

# 检查数据目录
check_data_directory() {
    echo -e "\n${CYAN}Data Directory:${NC}"
    
    local data_dir="$PROJECT_ROOT/data"
    
    if [ -d "$data_dir" ]; then
        echo -e "  Location: ${GREEN}✓${NC} $data_dir"
        
        # 计算数据目录大小
        local size
        size=$(du -sh "$data_dir" 2>/dev/null | cut -f1)
        echo "  Size: $size"
        
        # 检查权限
        if [ -r "$data_dir" ] && [ -w "$data_dir" ]; then
            echo -e "  Permissions: ${GREEN}✓${NC} readable and writable"
        else
            echo -e "  Permissions: ${RED}✗${NC} insufficient permissions"
        fi
        
        # 显示主要文件
        if [ "$(ls -A "$data_dir" 2>/dev/null)" ]; then
            echo "  Contents:"
            ls -la "$data_dir" | head -10 | while read line; do
                echo "    $line"
            done
        else
            echo -e "  Contents: ${YELLOW}⚠${NC} empty directory"
        fi
    else
        echo -e "  Location: ${RED}✗${NC} $data_dir not found"
    fi
}

# 检查日志文件
check_log_files() {
    echo -e "\n${CYAN}Log Files:${NC}"
    
    local log_file="$PROJECT_ROOT/logs/etcd.log"
    
    if [ -f "$log_file" ]; then
        echo -e "  Log file: ${GREEN}✓${NC} $log_file"
        
        # 显示文件大小
        local size
        size=$(ls -lh "$log_file" | awk '{print $5}')
        echo "  Size: $size"
        
        # 显示最近的日志条目
        echo "  Recent entries:"
        tail -5 "$log_file" 2>/dev/null | while read line; do
            echo "    $line"
        done
        
        # 检查是否有错误
        local error_count
        error_count=$(grep -c "ERROR\|FATAL" "$log_file" 2>/dev/null || echo "0")
        if [ "$error_count" -gt 0 ]; then
            echo -e "  Errors found: ${RED}⚠${NC} $error_count error(s) in log"
        else
            echo -e "  Errors: ${GREEN}✓${NC} no errors found"
        fi
    else
        echo -e "  Log file: ${YELLOW}⚠${NC} $log_file not found"
    fi
}

# 显示配置信息
show_configuration() {
    echo -e "\n${CYAN}Configuration:${NC}"
    
    # 显示环境变量配置
    echo "  Environment variables:"
    env | grep "^ETCD_" | while read line; do
        echo "    $line"
    done
    
    # 显示默认配置
    if [ -z "$(env | grep "^ETCD_")" ]; then
        echo "    Using default configuration:"
        echo "    ETCD_NAME=default"
        echo "    ETCD_DATA_DIR=$PROJECT_ROOT/data"
        echo "    ETCD_LISTEN_CLIENT_URLS=http://localhost:2379"
        echo "    ETCD_LISTEN_PEER_URLS=http://localhost:2380"
    fi
}

# 显示操作建议
show_suggestions() {
    echo -e "\n${CYAN}Available Operations:${NC}"
    echo "  Start:   scripts/start.sh"
    echo "  Stop:    scripts/stop.sh [--force]"
    echo "  Restart: scripts/restart.sh [--force] [--no-backup] [--quick]"
    echo "  Status:  scripts/status.sh [--detailed] [--watch]"
}

# 监控模式
watch_mode() {
    echo "Starting etcd status monitoring (press Ctrl+C to exit)..."
    echo "Refresh interval: 5 seconds"
    echo "=================================="
    
    while true; do
        clear
        echo -e "${CYAN}etcd Status Monitor${NC} - $(date)"
        echo "=================================="
        
        check_process_status > /dev/null
        local process_status=$?
        
        if [ $process_status -eq 0 ]; then
            echo -e "Status: ${GREEN}RUNNING${NC}"
            check_etcd_health > /dev/null 2>&1
            local health_status=$?
            if [ $health_status -eq 0 ]; then
                echo -e "Health: ${GREEN}HEALTHY${NC}"
            else
                echo -e "Health: ${YELLOW}DEGRADED${NC}"
            fi
        else
            echo -e "Status: ${RED}STOPPED${NC}"
        fi
        
        echo ""
        echo "Press Ctrl+C to exit monitoring mode"
        sleep 5
    done
}

# 主函数
main() {
    local detailed_mode=false
    local watch_mode_enabled=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--detailed)
                detailed_mode=true
                shift
                ;;
            -w|--watch)
                watch_mode_enabled=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -d, --detailed    Show detailed status information"
                echo "  -w, --watch       Continuous monitoring mode"
                echo "  -h, --help        Show this help message"
                echo ""
                echo "Description:"
                echo "  Check the status of etcd server including process,"
                echo "  ports, health, data directory, and logs."
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # 进入项目根目录
    cd "$PROJECT_ROOT" || {
        log_error "Failed to change to project directory: $PROJECT_ROOT"
        exit 1
    }
    
    # 监控模式
    if [ "$watch_mode_enabled" = true ]; then
        watch_mode
        exit 0
    fi
    
    # 显示状态信息
    echo -e "${CYAN}etcd Status Report${NC} - $(date)"
    echo "========================================"
    
    # 基础进程检查
    check_process_status
    local process_running=$?
    
    if [ $process_running -eq 0 ]; then
        # 如果进程在运行，进行更详细的检查
        check_port_status
        check_etcd_health
        
        if [ "$detailed_mode" = true ]; then
            check_data_directory
            check_log_files
            show_configuration
        fi
    else
        echo -e "\n${YELLOW}etcd is not running. Use 'scripts/start.sh' to start it.${NC}"
        
        if [ "$detailed_mode" = true ]; then
            check_data_directory
            check_log_files
        fi
    fi
    
    # 显示操作建议
    show_suggestions
    
    # 返回相应的退出码
    if [ $process_running -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# 执行主函数
main "$@"