# MongoDB Local Installation Tools

一个用于本地安装和管理 MongoDB 的工具集，提供了完整的安装、配置、启动、停止和监控功能。

## 项目结构

```
mongodb/
├── README.md                 # 项目说明文档
├── install.sh               # MongoDB 服务端安装脚本
├── install_client.sh        # MongoDB 客户端安装脚本
├── conf/                    # 配置文件目录
│   └── mongod.conf         # MongoDB 配置文件
├── scripts/                 # 管理脚本目录
│   ├── config.sh           # 配置文件更新脚本
│   ├── start.sh            # MongoDB 启动脚本
│   ├── stop.sh             # MongoDB 停止脚本
│   ├── restart.sh          # MongoDB 重启脚本
│   ├── status.sh           # MongoDB 状态检查脚本
│   └── condb.sh            # MongoDB 连接脚本
├── bin/                     # MongoDB 二进制文件目录 (安装后创建)
├── data/                    # 数据库数据目录 (安装后创建)
└── logs/                    # 日志文件目录 (安装后创建)
```

## 快速开始

### 1. 安装 MongoDB 服务端

```bash
# 安装 MongoDB 服务端和基础配置
./install.sh
```

这个脚本会：
- 下载 MongoDB 7.0.26-rc0 for Linux x64
- 创建必要的目录结构（bin、conf、data、logs）
- 下载官方配置文件模板
- 安装 MongoDB 二进制文件到 `bin/` 目录

### 2. 配置本地路径

```bash
# 配置 MongoDB 使用本地路径
./scripts/config.sh
```

这个脚本会：
- 更新配置文件中的数据路径为本地 `data/` 目录
- 更新日志路径为本地 `logs/` 目录
- 配置 PID 文件路径
- 设置绑定 IP 为 0.0.0.0（允许外部访问）
- 备份原始配置文件

### 3. 启动 MongoDB

```bash
# 启动 MongoDB 服务
./scripts/start.sh
```

### 4. 安装客户端工具（可选）

```bash
# 安装 MongoDB Shell 客户端
./install_client.sh
```

## 管理命令

### 基本操作

```bash
# 启动 MongoDB
./scripts/start.sh

# 停止 MongoDB
./scripts/stop.sh

# 重启 MongoDB
./scripts/restart.sh

# 检查状态
./scripts/status.sh

# 连接到数据库
./scripts/condb.sh
```

### 状态检查

`./scripts/status.sh` 提供详细的状态信息：
- MongoDB 二进制文件版本
- 配置文件状态
- 数据目录大小
- 日志文件大小
- 进程运行状态
- 端口监听状态
- 连接测试结果
- 最近的日志条目

## 配置说明

### 默认配置

- **端口**: 27017
- **数据目录**: `./data/`
- **日志文件**: `./logs/mongod.log`
- **配置文件**: `./conf/mongod.conf`
- **PID 文件**: `./data/mongod.pid`
- **绑定 IP**: 0.0.0.0（允许所有 IP 访问）

### 安全提醒

⚠️ **重要安全提示**：
- 当前配置允许从任何 IP 地址连接
- 生产环境中请考虑：
  - 启用身份验证 (`--auth`)
  - 使用特定 IP 地址而不是 0.0.0.0
  - 设置 SSL/TLS 加密
  - 配置防火墙规则

### 自定义配置

如需修改配置：
1. 编辑 `conf/mongod.conf` 文件
2. 运行 `./scripts/config.sh` 重新配置
3. 重启 MongoDB：`./scripts/restart.sh`

## 支持的 MongoDB 版本

- **服务端**: MongoDB 7.0.26-rc0 for Linux x64
- **客户端**: MongoDB Shell (mongosh) 2.1.0

## 系统要求

- Linux x64 系统
- bash shell
- wget 或 curl（用于下载）
- 足够的磁盘空间存储数据和日志

## 故障排除

### 常见问题

1. **MongoDB 无法启动**
   ```bash
   # 检查状态和错误日志
   ./scripts/status.sh
   # 查看完整日志
   tail -f logs/mongod.log
   ```

2. **端口已被占用**
   ```bash
   # 检查端口使用情况
   netstat -tlnp | grep 27017
   # 或使用 ss
   ss -tlnp | grep 27017
   ```

3. **权限问题**
   ```bash
   # 确保脚本有执行权限
   chmod +x scripts/*.sh
   chmod +x *.sh
   ```

4. **配置文件问题**
   ```bash
   # 重新下载和配置
   rm conf/mongod.conf
   ./install.sh
   ./scripts/config.sh
   ```

### 日志位置

- **MongoDB 日志**: `logs/mongod.log`
- **配置备份**: `conf/mongod.conf.bak.*`

## 开发和贡献

### 脚本功能

- `install.sh`: 主安装脚本，下载并设置 MongoDB 服务端
- `install_client.sh`: 客户端工具安装
- `scripts/config.sh`: 配置文件自动化配置
- `scripts/start.sh`: 智能启动，包含预检查
- `scripts/stop.sh`: 优雅停止，支持强制终止
- `scripts/restart.sh`: 安全重启
- `scripts/status.sh`: 全面状态检查和诊断
- `scripts/condb.sh`: 自动检测客户端类型并连接

### 扩展功能

可以根据需要添加更多管理脚本：
- 数据备份和恢复
- 用户管理
- 数据库管理
- 性能监控

## 许可证

本项目遵循 MongoDB 的许可证条款。请参考 MongoDB 官方文档了解详细的许可证信息。

## 相关链接

- [MongoDB 官方文档](https://docs.mongodb.com/)
- [MongoDB 下载页面](https://www.mongodb.com/try/download/community)
- [MongoDB Shell 文档](https://docs.mongodb.com/mongodb-shell/)