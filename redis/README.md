# Redis 安装和管理工具

这是一个便于安装、配置和管理 Redis 服务器的 Shell 脚本工具集。通过简单的脚本命令，您可以快速部署和管理 Redis 实例。

## 📁 项目结构

```
redis/
├── install.sh          # Redis 安装脚本
├── conf/               # 配置文件目录
│   └── redis.conf      # Redis 配置文件
├── data/               # 数据存储目录
├── scripts/            # 管理脚本目录
│   ├── configure.sh    # 配置脚本
│   ├── start.sh        # 启动脚本
│   ├── stop.sh         # 停止脚本
│   ├── restart.sh      # 重启脚本
│   └── status.sh       # 状态检查脚本
└── bin/                # Redis 二进制文件目录 (安装后生成)
    ├── redis-server    # Redis 服务器
    ├── redis-cli       # Redis 客户端
    └── ...
```

## 🚀 快速开始

### 1. 安装 Redis

首先运行安装脚本来下载、编译和安装 Redis：

```bash
./install.sh
```

安装脚本会：
- 下载 Redis 7.2.11 源码
- 编译 Redis
- 安装到 `bin/` 目录
- 复制官方配置文件到 `conf/` 目录
- 创建必要的目录结构

### 2. 配置 Redis

运行配置脚本来优化 Redis 设置：

```bash
./scripts/configure.sh
```

配置脚本会：
- 设置数据目录路径
- 启用后台运行模式
- 配置日志和 PID 文件路径
- 启用 AOF 持久化
- 允许远程访问（可选）
- 备份原始配置文件

### 3. 启动 Redis

```bash
./scripts/start.sh
```

### 4. 检查状态

```bash
./scripts/status.sh
```

## 📋 管理命令

| 脚本 | 功能 | 描述 |
|------|------|------|
| `./install.sh` | 安装 Redis | 下载、编译并安装 Redis 7.2.11 |
| `./scripts/configure.sh` | 配置 Redis | 优化配置文件，设置路径和参数 |
| `./scripts/start.sh` | 启动服务 | 启动 Redis 服务器 |
| `./scripts/stop.sh` | 停止服务 | 优雅关闭 Redis 服务器 |
| `./scripts/restart.sh` | 重启服务 | 停止并重新启动 Redis 服务器 |
| `./scripts/status.sh` | 状态检查 | 检查 Redis 运行状态和基本信息 |

## ⚙️ 配置说明

### 默认配置

安装后的默认配置包括：

- **端口**: 6379 (Redis 默认端口)
- **数据目录**: `./data/`
- **配置文件**: `./conf/redis.conf`
- **日志文件**: `./data/redis.log`
- **PID 文件**: `./data/redis.pid`
- **持久化**: AOF 模式，每秒同步
- **网络访问**: 绑定到 0.0.0.0 (允许远程连接)
- **保护模式**: 已关闭

### 自定义配置

如需修改配置，可以直接编辑 `conf/redis.conf` 文件，或者修改 `scripts/configure.sh` 脚本来调整默认设置。

### 重要安全提示

⚠️ **安全警告**: 默认配置允许远程访问且未设置密码。在生产环境中，请：

1. 设置强密码：
   ```bash
   # 在 redis.conf 中添加或修改
   requirepass your_strong_password
   ```

2. 限制网络访问：
   ```bash
   # 仅允许本地访问
   bind 127.0.0.1
   
   # 或指定特定IP
   bind 192.168.1.10
   ```

3. 启用保护模式：
   ```bash
   protected-mode yes
   ```

## 📊 状态监控

使用 `./scripts/status.sh` 可以查看：

- Redis 进程状态
- 服务响应状态
- 版本信息
- 内存使用情况
- 连接数统计
- 运行时长

## 🔧 故障排除

### 常见问题

1. **编译失败**
   - 确保系统已安装 gcc、make 等编译工具
   - 检查网络连接，确保能下载源码

2. **启动失败**
   - 检查配置文件语法：`./bin/redis-server --test-config ./conf/redis.conf`
   - 查看日志文件：`cat ./data/redis.log`
   - 确保端口 6379 未被占用

3. **连接失败**
   - 检查防火墙设置
   - 确认网络配置（bind 参数）
   - 验证密码设置

### 日志查看

```bash
# 查看最新日志
tail -f ./data/redis.log

# 查看错误信息
grep -i error ./data/redis.log
```

## 🔄 数据备份

Redis 使用 AOF 持久化模式，数据文件位于：
- `./data/appendonly.aof` - AOF 日志文件
- `./data/redis.log` - 服务日志文件

定期备份这些文件以确保数据安全。

## 📝 版本信息

- **Redis 版本**: 7.2.11
- **安装方式**: 源码编译
- **支持平台**: Linux/Unix 系统

## 🤝 贡献

欢迎提交问题和改进建议！

## 📄 许可证

本项目遵循 Redis 的开源许可证。

---

**快速命令参考**:
```bash
# 一键安装和启动
./install.sh && ./scripts/configure.sh && ./scripts/start.sh

# 检查状态
./scripts/status.sh

# 停止服务
./scripts/stop.sh
```