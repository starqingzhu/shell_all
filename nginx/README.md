# Nginx 自动化管理工具

一套完整的nginx源码编译、安装、配置和服务管理工具集，支持SSL/HTTPS部署，适用于开发、测试和生产环境。

## 🎯 项目特点

- **一键安装**: 自动化nginx源码编译和安装
- **智能管理**: 完整的服务启动、停止、重启、状态检查
- **SSL支持**: 自动SSL证书生成和HTTPS部署
- **路径智能**: 基于相对路径的便携式部署
- **增量安装**: 智能检测已有文件，避免重复下载和编译
- **备份机制**: 安装前自动备份现有版本

## 📁 项目结构

```
nginx/
├── install.sh              # nginx源码编译安装脚本
├── conf/                   # nginx配置文件目录
│   └── nginx.conf          # nginx主配置文件
├── scripts/                # 服务管理脚本目录
│   ├── nginx_config.sh     # 公共配置文件
│   ├── start.sh           # nginx启动脚本
│   ├── stop.sh            # nginx停止脚本
│   ├── restart.sh         # nginx重启脚本
│   ├── status.sh          # nginx状态检查脚本
│   ├── reload.sh          # nginx配置重载脚本
│   ├── README.md          # 服务管理脚本说明
│   ├── conf/              # 配置管理脚本
│   │   └── fix_nginx_paths.sh  # 路径修复脚本
│   └── ssl/               # SSL证书管理脚本
│       ├── ssl_config.sh   # SSL公共配置
│       ├── init_ssl.sh     # SSL证书初始化
│       ├── manage_ssl.sh   # SSL证书管理
│       ├── quick_deploy_https.sh  # HTTPS快速部署
│       └── README.md       # SSL脚本详细说明
└── 运行时目录 (安装后创建)
    ├── bin/               # nginx可执行文件
    ├── logs/              # nginx日志文件
    ├── run/               # nginx PID文件
    ├── ssl/               # SSL证书文件
    ├── temp/              # nginx临时文件
    └── package/           # nginx源码包（安装时）
```

## 🚀 快速开始

### 1. 克隆或下载项目
```bash
# 克隆项目到本地
git clone <repository-url> nginx-tools
cd nginx-tools
```

### 2. 一键安装nginx
```bash
# 确保有执行权限
chmod +x install.sh
chmod +x scripts/*.sh
chmod +x scripts/ssl/*.sh

# 执行安装（包含依赖检查和自动安装）
./install.sh
```

### 3. 启动nginx服务
```bash
cd scripts
./start.sh
```

### 4. 检查服务状态
```bash
./status.sh
```

### 5. 配置HTTPS（可选）
```bash
cd ssl
./quick_deploy_https.sh
```

## 🔧 详细安装说明

### 系统要求

**支持的操作系统**:
- CentOS/RHEL 7/8
- Ubuntu 16.04+
- 其他Linux发行版（需手动安装依赖）

**必需的依赖**:
- gcc编译器
- make构建工具
- pcre-devel (正则表达式库)
- openssl-devel (SSL支持)
- zlib-devel (压缩支持)
- wget (下载工具)

### 安装过程

`install.sh` 脚本会自动完成以下步骤：

1. **环境检查**: 检查编译依赖，自动安装缺失项
2. **源码下载**: 从nginx官网下载指定版本源码
3. **智能编译**: 检测已有编译结果，避免重复编译
4. **版本备份**: 安装前备份现有nginx版本
5. **目录创建**: 创建所需的运行时目录结构
6. **权限设置**: 设置适当的文件和目录权限

### 配置选项

nginx编译时包含以下模块：
- SSL/TLS支持
- HTTP/2支持
- Gzip压缩
- 实时IP模块
- 状态监控模块
- 文件AIO支持

## 📋 服务管理

### 基础操作

```bash
cd scripts

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

### 配置管理

```bash
# 测试配置文件语法
../bin/nginx -t -c ../conf/nginx.conf

# 查看nginx版本和编译选项
../bin/nginx -V

# 手动重载配置
../bin/nginx -s reload
```

## 🔒 SSL/HTTPS配置

### 快速部署HTTPS
```bash
cd scripts/ssl

# 一键HTTPS部署（推荐）
./quick_deploy_https.sh

# 或分步操作
./init_ssl.sh          # 生成SSL证书
cd ..
./restart.sh           # 重启nginx
```

### SSL证书管理
```bash
cd scripts/ssl

# 检查证书状态
./manage_ssl.sh check

# 查看证书信息
./manage_ssl.sh info

# 验证证书有效性
./manage_ssl.sh verify

# 重新生成证书
./manage_ssl.sh renew

# 备份证书
./manage_ssl.sh backup
```

### 证书类型选择

**SAN扩展证书**（推荐）:
- 支持多域名和IP地址
- 包含localhost、127.0.0.1、nginx.local等常用名称
- 适合开发和测试环境

**标准证书**:
- 仅支持单一通用名称
- 配置简单，兼容性好

## 🔧 配置说明

### nginx配置文件

主配置文件位于 `conf/nginx.conf`，当前配置特点：

- **双端口支持**: HTTP(8081) 和 HTTPS(8443)
- **API代理**: 支持 `/api/globalserver/` 和 `/api/gameserver/` 接口代理
- **日志分离**: 不同类型请求使用独立日志文件
- **SSL优化**: 使用现代SSL协议和加密套件

### 路径配置

所有脚本使用相对路径，基于以下目录结构：

```bash
NGINX_HOME     # nginx主目录（当前项目目录）
NGINX_BIN      # ../bin/nginx
NGINX_CONF     # ../conf/nginx.conf
NGINX_PID      # ../run/nginx.pid
SSL_CERT       # ../ssl/nginx.crt
SSL_KEY        # ../ssl/nginx.key
```

## 🔍 故障排除

### 常见问题

#### 1. 编译依赖缺失
```bash
# CentOS/RHEL
sudo yum groupinstall -y 'Development Tools'
sudo yum install -y pcre-devel openssl-devel zlib-devel wget

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y build-essential libpcre3-dev libssl-dev zlib1g-dev wget
```

#### 2. nginx启动失败
```bash
# 检查配置语法
cd scripts
../bin/nginx -t -c ../conf/nginx.conf

# 查看错误日志
tail -20 ../logs/error.log

# 检查端口占用
netstat -tlnp | grep :8081
```

#### 3. SSL证书问题
```bash
cd scripts/ssl

# 检查SSL状态
./manage_ssl.sh check

# 查看详细错误
./manage_ssl.sh info

# 重新生成证书
./manage_ssl.sh renew
```

#### 4. 权限问题
```bash
# 设置脚本执行权限
chmod +x install.sh
chmod +x scripts/*.sh
chmod +x scripts/ssl/*.sh

# 设置SSL证书权限
chmod 600 ssl/nginx.key
chmod 644 ssl/nginx.crt
```

### 日志分析

```bash
# 实时监控错误日志
tail -f logs/error.log

# 实时监控访问日志
tail -f logs/access.log

# 查看API代理日志
tail -f logs/api_proxy.log
tail -f logs/https_api_proxy.log
```

## 🧪 测试验证

### HTTP服务测试
```bash
# 测试HTTP服务
curl -I http://localhost:8081

# 测试API代理
curl http://localhost:8081/api/globalserver/health
```

### HTTPS服务测试
```bash
# 测试HTTPS服务（忽略证书警告）
curl -k -I https://localhost:8443

# 测试HTTPS API代理
curl -k https://localhost:8443/api/globalserver/health

# 查看SSL证书信息
openssl s_client -connect localhost:8443 -servername localhost
```

### 性能测试
```bash
# 使用ab进行简单性能测试
ab -n 1000 -c 10 http://localhost:8081/

# 使用curl测试响应时间
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8081/
```

## 📊 监控和维护

### 服务监控
```bash
cd scripts

# 检查服务状态
./status.sh

# 查看进程信息
ps aux | grep nginx

# 查看端口监听
netstat -tlnp | grep nginx
```

### 日志管理
```bash
# 日志轮转配置建议
cat > /etc/logrotate.d/nginx << EOF
logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 nginx nginx
    postrotate
        if [ -f ../run/nginx.pid ]; then
            kill -USR1 \`cat ../run/nginx.pid\`
        fi
    endscript
}
EOF
```

### 定期维护
```bash
# 清理过期日志（保留7天）
find logs/ -name "*.log.*" -mtime +7 -delete

# 检查SSL证书有效期
cd scripts/ssl
./manage_ssl.sh check

# 备份配置文件
tar -czf nginx-config-$(date +%Y%m%d).tar.gz conf/ ssl/
```

## 🔗 高级配置

### 负载均衡配置
```nginx
upstream backend {
    server 192.168.1.10:8001;
    server 192.168.1.11:8001;
    server 192.168.1.12:8001;
}

location /api/ {
    proxy_pass http://backend;
}
```

### 缓存配置
```nginx
proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=my_cache:10m inactive=60m;

location /static/ {
    proxy_cache my_cache;
    proxy_cache_valid 200 302 10m;
    proxy_cache_valid 404 1m;
}
```

### 安全配置
```nginx
# 隐藏nginx版本
server_tokens off;

# 安全头
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
```

## 📚 版本信息

- **nginx版本**: 1.28.0
- **OpenSSL**: 系统默认版本
- **编译模块**: 包含SSL、HTTP/2、Gzip等主要模块
- **支持协议**: HTTP/1.1, HTTP/2, SSL/TLS

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进这个工具集。

### 开发规范
- 遵循Shell脚本最佳实践
- 保持向后兼容性
- 添加适当的错误处理
- 更新相关文档

### 测试流程
- 在不同Linux发行版上测试
- 验证SSL证书生成和部署
- 检查服务管理功能
- 测试故障恢复机制

## 📄 许可证

本项目采用 MIT 许可证。详见 LICENSE 文件。

## 📞 技术支持

如遇问题，请按以下顺序排查：

1. 查看 `scripts/README.md` 了解服务管理
2. 查看 `scripts/ssl/README.md` 了解SSL配置
3. 运行 `scripts/status.sh` 检查服务状态
4. 查看 `logs/error.log` 错误日志
5. 检查配置文件语法: `bin/nginx -t`

---

**维护建议**: 定期更新nginx版本，检查SSL证书有效期，监控服务运行状态。

**生产部署**: 建议使用正式CA证书，配置防火墙规则，设置日志轮转。

*本工具集致力于简化nginx的部署和管理，提高开发和运维效率。*