# Nginx 服务管理脚本

本目录包含nginx服务的完整管理脚本集合，提供安装、配置、启动、停止、重启、状态检查、SSL证书管理等功能。

## 📁 目录结构

```
scripts/
├── nginx_config.sh        # nginx公共配置文件
├── start.sh              # nginx启动脚本
├── stop.sh               # nginx停止脚本
├── restart.sh            # nginx重启脚本
├── status.sh             # nginx状态检查脚本
├── reload.sh             # nginx配置重载脚本
├── ssl/                  # SSL证书管理目录
│   ├── ssl_config.sh     # SSL公共配置文件
│   ├── init_ssl.sh       # SSL证书初始化脚本
│   ├── manage_ssl.sh     # SSL证书管理脚本
│   ├── quick_deploy_https.sh # HTTPS快速部署脚本
│   └── README.md         # SSL脚本说明文档
└── README.md             # 本说明文档
```

## 🚀 快速开始

### 1. 安装nginx
```bash
# 在项目根目录运行安装脚本
cd ..
./install.sh
```

### 2. 启动nginx服务
```bash
./start.sh
```

### 3. 检查服务状态
```bash
./status.sh
```

### 4. 配置HTTPS（可选）
```bash
cd ssl
./quick_deploy_https.sh
```

## 🔧 配置说明

### 基础路径配置
所有脚本使用相对路径，基于以下目录结构：
```
nginx/                  # 项目根目录
├── bin/               # nginx可执行文件
├── conf/              # nginx配置文件
├── logs/              # nginx日志文件
├── run/               # nginx PID文件
├── ssl/               # SSL证书文件
└── scripts/           # 管理脚本目录
```

### nginx_config.sh - 公共配置
所有脚本依赖 `nginx_config.sh` 配置文件，包含以下核心配置：

```bash
NGINX_HOME               # nginx主目录（相对于scripts目录的上级目录）
NGINX_BIN               # nginx可执行文件路径 (../bin/nginx)
NGINX_CONF              # nginx配置文件路径 (../conf/nginx.conf)
NGINX_PID               # nginx PID文件路径 (../run/nginx.pid)
NGINX_ERROR_LOG         # nginx错误日志路径 (../logs/error.log)
NGINX_ACCESS_LOG        # nginx访问日志路径 (../logs/access.log)
```

## 📋 脚本详细说明

### 基础服务管理脚本

#### `nginx_config.sh` - 公共配置文件

**功能**: 定义所有脚本的公共路径和配置

**主要配置项**:
- `NGINX_HOME` - nginx主目录（相对于scripts目录的上级目录）
- `NGINX_BIN` - nginx可执行文件路径
- `NGINX_CONF` - nginx配置文件路径
- `NGINX_PID` - nginx PID文件路径
- `NGINX_ERROR_LOG` - nginx错误日志路径
- `NGINX_ACCESS_LOG` - nginx访问日志路径

#### `start.sh` - nginx启动脚本

**功能**: 启动nginx服务

**执行流程**:
1. 检查nginx可执行文件是否存在
2. 检查配置文件语法
3. 检查是否已经运行
4. 创建必要目录
5. 启动nginx服务

#### `stop.sh` - nginx停止脚本

**功能**: 停止nginx服务

**停止策略**:
1. 优雅停止 (QUIT信号)
2. 快速停止 (TERM信号)
3. 强制停止 (KILL信号)
4. 清理PID文件

#### `restart.sh` - nginx重启脚本

**功能**: 重启nginx服务

**执行流程**: 调用stop.sh停止服务 → 等待服务完全停止 → 调用start.sh启动服务

#### `status.sh` - nginx状态检查脚本

**功能**: 检查nginx服务运行状态

**检查内容**:
- nginx可执行文件存在性
- PID文件状态
- 进程运行状态
- 端口监听情况

#### `reload.sh` - nginx配置重载脚本

**功能**: 重新加载nginx配置文件

**执行流程**:
1. 检查nginx是否运行
2. 测试配置文件语法
3. 发送重载信号
4. 验证重载结果

### SSL证书管理脚本（ssl/ 目录）

详细的SSL脚本使用说明请参考 `ssl/README.md` 文档。

#### `ssl_config.sh` - SSL配置文件

**功能**: SSL相关的配置和函数定义，扩展nginx_config.sh

#### `init_ssl.sh` - SSL证书初始化

**功能**: 交互式SSL证书生成，支持基础证书和SAN扩展证书

#### `manage_ssl.sh` - SSL证书管理

**功能**: 完整的SSL证书管理工具
- `check` - 检查SSL证书状态
- `info` - 查看证书信息
- `verify` - 验证证书
- `renew` - 重新生成证书
- `backup` - 备份证书

#### `quick_deploy_https.sh` - HTTPS快速部署

**功能**: 一键部署HTTPS服务，自动完成证书生成和nginx配置

## 🔧 使用示例

### 基础操作

```bash
# 启动nginx
./start.sh

# 停止nginx
./stop.sh

# 重启nginx
./restart.sh

# 查看状态
./status.sh

# 重载配置
./reload.sh
```

### HTTPS部署

```bash
# 进入SSL目录
cd ssl

# 一键HTTPS部署（推荐）
./quick_deploy_https.sh

# 或者分步操作
./init_ssl.sh           # 初始化SSL证书
cd ..
./restart.sh            # 重启nginx

# SSL证书管理
cd ssl
./manage_ssl.sh check   # 检查SSL状态
./manage_ssl.sh info    # 查看证书信息
./manage_ssl.sh renew   # 重新生成证书
```

### 故障排除

```bash
# 查看详细状态
./status.sh

# 检查配置语法
../bin/nginx -t -c ../conf/nginx.conf

# 查看错误日志
tail -20 ../logs/error.log
```

## �️ 常用操作

### 日志监控
```bash
# 实时监控错误日志
tail -f ../logs/error.log

# 实时监控访问日志
tail -f ../logs/access.log

# 查看最近的错误
tail -20 ../logs/error.log
```

### 配置管理
```bash
# 测试配置文件语法
../bin/nginx -t -c ../conf/nginx.conf

# 查看nginx版本和编译选项
../bin/nginx -V

# 手动重载配置
../bin/nginx -s reload -c ../conf/nginx.conf
```

## 🔍 故障排除指南

### 常见问题

#### 1. nginx启动失败
```bash
# 检查配置文件语法
./start.sh    # 脚本会自动检查

# 手动检查
../bin/nginx -t -c ../conf/nginx.conf

# 查看错误日志
tail -20 ../logs/error.log
```

#### 2. 端口冲突
```bash
# 检查端口占用
netstat -tlnp | grep :8081

# 查看进程
ps aux | grep nginx
```

#### 3. 权限问题
```bash
# 检查文件权限
ls -la ../bin/nginx
ls -la ../conf/nginx.conf

# 设置执行权限
chmod +x ../bin/nginx
chmod +x *.sh
```

#### 4. PID文件问题
```bash
# 清理无效PID文件
rm -f ../run/nginx.pid

# 手动查找nginx进程
ps aux | grep nginx | grep -v grep
```

#### 5. SSL证书问题
```bash
# 检查SSL证书状态
cd ssl
./manage_ssl.sh check

# 重新生成SSL证书
./manage_ssl.sh renew

# 查看证书信息
./manage_ssl.sh info
```

### 日志分析
```bash
# 查看错误日志
tail -f ../logs/error.log

# 查看访问日志
tail -f ../logs/access.log

# 查看最近错误
tail -20 ../logs/error.log
```

## ⚠️ 注意事项

### 安全考虑

1. **文件权限**: 确保脚本有适当的执行权限
2. **SSL证书**: 生产环境使用正式CA证书，不要使用自签名证书
3. **配置安全**: 定期检查nginx配置安全性

### 维护建议

1. **定期备份**: 备份配置文件和SSL证书
2. **日志轮转**: 配置日志轮转避免磁盘满
3. **监控服务**: 设置服务监控和报警
4. **更新维护**: 定期更新nginx版本

### 开发vs生产

- **开发环境**: 可使用自签名证书和简化配置
- **生产环境**: 必须使用正式证书和安全配置

## 📚 更多信息

### 相关文件

- `../conf/nginx.conf` - 主配置文件
- `../logs/error.log` - 错误日志
- `../logs/access.log` - 访问日志
- `../run/nginx.pid` - 进程ID文件
- `../ssl/nginx.crt` - SSL证书文件
- `../ssl/nginx.key` - SSL私钥文件

### nginx命令参考
```bash
../bin/nginx -h          # 显示帮助
../bin/nginx -v          # 显示版本
../bin/nginx -V          # 显示版本和编译选项
../bin/nginx -t          # 测试配置
../bin/nginx -s reload   # 重载配置
../bin/nginx -s stop     # 停止服务
```

## 📞 技术支持

如遇问题，请按以下顺序排查：

1. 运行 `./status.sh` 检查基本状态
2. 查看 `../logs/error.log` 错误日志
3. 运行 `../bin/nginx -t` 检查配置语法
4. 检查端口占用和进程状态
5. 确认文件权限和路径正确性

更多SSL相关问题请参考 `ssl/README.md` 文档。

---

## 📝 更新日志

### v2.0.0

- 简化脚本结构，专注核心功能
- 每个脚本单一职责，提高可维护性
- 完善的SSL证书管理系统
- 详细的故障排除指南
- 标准化的配置管理

---

*本脚本集合旨在简化nginx的部署和管理。所有脚本都经过测试，适用于开发和生产环境。*