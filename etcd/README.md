# etcd管理脚本

这是一套用于管理etcd服务器的shell脚本，包括启动、停止、重启和状态检查功能。

## 目录结构

```
etcd/
├── install.sh          # etcd安装脚本
├── scripts/            # 管理脚本目录
│   ├── start.sh        # 启动脚本
│   ├── stop.sh         # 停止脚本
│   ├── restart.sh      # 重启脚本
│   └── status.sh       # 状态检查脚本
├── bin/                # etcd二进制文件目录
├── data/               # etcd数据存储目录
├── logs/               # 日志文件目录
└── backup/             # 数据备份目录
```

## 使用方法

### 1. 安装etcd

首先运行安装脚本来下载和安装etcd：

```bash
./install.sh
```

### 2. 启动etcd

使用启动脚本启动etcd服务：

```bash
./scripts/start.sh
```

启动脚本会：
- 检查etcd二进制文件是否存在
- 创建必要的数据目录
- 检查是否已经有实例在运行
- 使用默认配置启动etcd
- 进行健康检查

### 3. 检查状态

查看etcd运行状态：

```bash
# 基础状态检查
./scripts/status.sh

# 详细状态信息
./scripts/status.sh --detailed

# 持续监控模式
./scripts/status.sh --watch
```

状态脚本会显示：
- 进程运行状态
- 端口监听状态
- 健康检查结果
- 数据目录信息
- 日志文件状态

### 4. 停止etcd

停止etcd服务：

```bash
# 优雅停止
./scripts/stop.sh

# 强制停止
./scripts/stop.sh --force
```

停止脚本会：
- 首先尝试优雅停止(SIGTERM)
- 等待进程退出
- 如果需要，进行强制停止(SIGKILL)
- 清理PID文件

### 5. 重启etcd

重启etcd服务：

```bash
# 标准重启
./scripts/restart.sh

# 强制重启
./scripts/restart.sh --force

# 快速重启（跳过健康检查）
./scripts/restart.sh --quick

# 重启时不备份数据
./scripts/restart.sh --no-backup
```

重启脚本会：
- 自动备份数据（除非使用--no-backup）
- 停止当前运行的etcd
- 等待进程完全退出
- 启动新的etcd实例
- 进行健康检查

## 配置选项

可以通过环境变量自定义etcd配置：

```bash
# 设置节点名称
export ETCD_NAME="node1"

# 设置数据目录
export ETCD_DATA_DIR="/custom/data/path"

# 设置监听地址
export ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
export ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"

# 设置广播地址
export ETCD_ADVERTISE_CLIENT_URLS="http://192.168.1.100:2379"
export ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.1.100:2380"

# 设置集群配置
export ETCD_INITIAL_CLUSTER="node1=http://192.168.1.100:2380,node2=http://192.168.1.101:2380"
export ETCD_INITIAL_CLUSTER_STATE="new"
export ETCD_INITIAL_CLUSTER_TOKEN="my-etcd-cluster"
```

## 默认配置

如果没有设置环境变量，脚本会使用以下默认配置：

- **节点名称**: default
- **数据目录**: ./data
- **客户端端口**: 2379
- **节点间通信端口**: 2380
- **监听地址**: localhost
- **集群模式**: 单节点

## 日志和监控

- **日志文件**: `logs/etcd.log`
- **PID文件**: `etcd.pid`
- **数据备份**: `backup/etcd_data_backup_YYYYMMDD_HHMMSS`

### 查看日志

```bash
# 查看最新日志
tail -f logs/etcd.log

# 查看错误日志
grep "ERROR\|FATAL" logs/etcd.log
```

### 使用etcdctl

```bash
# 检查集群健康
./bin/etcdctl --endpoints=http://localhost:2379 endpoint health

# 查看集群成员
./bin/etcdctl --endpoints=http://localhost:2379 member list

# 设置键值
./bin/etcdctl --endpoints=http://localhost:2379 put mykey "myvalue"

# 获取键值
./bin/etcdctl --endpoints=http://localhost:2379 get mykey
```

## 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -tln | grep :2379
   netstat -tln | grep :2380
   ```

2. **权限问题**
   ```bash
   # 确保脚本有执行权限
   chmod +x scripts/*.sh
   
   # 确保数据目录有写权限
   chmod 755 data/
   ```

3. **进程残留**
   ```bash
   # 查找残留进程
   pgrep -f etcd
   
   # 强制清理
   ./scripts/stop.sh --force
   ```

4. **数据损坏**
   ```bash
   # 从备份恢复
   rm -rf data/
   cp -r backup/etcd_data_backup_YYYYMMDD_HHMMSS data/
   ```

### 脚本参数说明

#### start.sh
- 无参数选项，使用环境变量或默认配置

#### stop.sh
- `-f, --force`: 强制停止进程
- `-h, --help`: 显示帮助信息

#### restart.sh
- `-f, --force`: 强制重启
- `--no-backup`: 跳过数据备份
- `-q, --quick`: 快速重启
- `-h, --help`: 显示帮助信息

#### status.sh
- `-d, --detailed`: 显示详细状态
- `-w, --watch`: 持续监控模式
- `-h, --help`: 显示帮助信息

## 安全建议

1. **生产环境配置**
   - 使用TLS加密通信
   - 配置身份认证
   - 限制网络访问
   - 定期备份数据

2. **监控告警**
   - 监控进程状态
   - 监控磁盘使用
   - 监控网络连接
   - 设置健康检查告警

3. **数据备份**
   - 定期自动备份
   - 验证备份完整性
   - 测试恢复流程

## 版本信息

- etcd版本: 3.5.24
- 脚本版本: 1.0
- 兼容系统: Linux/Unix