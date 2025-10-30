# SSL证书管理脚本

本目录包含nginx SSL证书的生成、管理和部署脚本集合。

## 📁 目录结构

```
ssl/
├── ssl_config.sh           # SSL公共配置文件
├── init_ssl.sh            # SSL证书初始化脚本（支持选择证书类型）
├── manage_ssl.sh          # SSL证书管理脚本
├── quick_deploy_https.sh  # HTTPS快速部署脚本
└── README.md             # 本说明文档
```

## 🚀 快速开始

### 1. 初始化SSL证书（推荐）
```bash
./init_ssl.sh
```
- 支持选择标准证书或SAN扩展证书
- 默认生成SAN扩展证书（推荐）
- 自动备份现有证书

### 2. 快速部署HTTPS
```bash
./quick_deploy_https.sh
```
- 一键完成HTTPS配置
- 自动检查环境和依赖
- 重启nginx服务

## 📋 脚本详细说明

### ssl_config.sh - SSL公共配置
**功能**: SSL相关的公共配置和函数库

**主要配置项**:
```bash
SSL_COMMON_NAME="localhost"      # SSL通用名称
SSL_EMAIL="admin@localhost"      # SSL邮箱
SSL_DAYS=365                     # 证书有效期（天）
SSL_KEY_LENGTH=2048             # 密钥长度
```

**配置修改建议**:
- **开发环境**: 保持默认配置
- **生产环境**: 修改为实际域名和邮箱
- **公网部署**: 使用公网IP或域名

### init_ssl.sh - SSL证书初始化
**功能**: 交互式生成SSL证书

**使用方法**:
```bash
./init_ssl.sh
```

**证书类型选择**:
- `1` - 标准SSL证书（仅支持通用名称）
- `2` - SAN扩展SSL证书（支持多域名/IP，默认推荐）

**SAN扩展支持**:
- localhost
- nginx.local
- api.local
- ssl.local
- 127.0.0.1
- ::1 (IPv6)

### manage_ssl.sh - SSL证书管理
**功能**: SSL证书的查看、验证、管理

**使用方法**:
```bash
./manage_ssl.sh [选项]
```

**可用选项**:
- `check` - 检查SSL证书状态
- `info` - 显示证书详细信息
- `verify` - 验证证书和私钥匹配
- `renew` - 重新生成证书
- `backup` - 备份现有证书

**示例**:
```bash
./manage_ssl.sh check    # 检查证书状态
./manage_ssl.sh info     # 查看证书详细信息
./manage_ssl.sh verify   # 验证证书匹配性
```

### quick_deploy_https.sh - HTTPS快速部署
**功能**: 一键部署HTTPS服务

**使用方法**:
```bash
./quick_deploy_https.sh
```

**部署流程**:
1. 检查nginx环境和SSL模块
2. 检查OpenSSL工具
3. 初始化或验证SSL证书
4. 测试nginx配置
5. 重启nginx服务

## 🔧 配置说明

### SSL证书配置
在 `ssl_config.sh` 中修改以下配置：

```bash
# 基本信息
SSL_COUNTRY="CN"                    # 国家
SSL_STATE="Beijing"                 # 省/州
SSL_CITY="Beijing"                  # 城市
SSL_ORG="Local Development"         # 组织
SSL_UNIT="IT Department"            # 部门

# 关键配置
SSL_COMMON_NAME="localhost"         # 通用名称
SSL_EMAIL="admin@localhost"         # 邮箱地址
SSL_DAYS=365                        # 有效期
SSL_KEY_LENGTH=2048                 # 密钥长度
```

### 不同环境配置建议

#### 开发/测试环境
```bash
SSL_COMMON_NAME="localhost"
SSL_EMAIL="admin@localhost"
```

#### 生产环境
```bash
SSL_COMMON_NAME="your-domain.com"
SSL_EMAIL="admin@your-domain.com"
```

#### 公网IP部署
```bash
SSL_COMMON_NAME="123.456.789.123"
SSL_EMAIL="your-email@example.com"
```

## 📁 生成的文件

SSL证书生成后，会在 `../../ssl/` 目录下创建：

```
ssl/
├── nginx.crt              # SSL证书文件
├── nginx.key              # SSL私钥文件
└── backup.YYYYMMDD_HHMMSS/  # 备份目录（如有）
    ├── nginx.crt          # 备份的证书
    └── nginx.key          # 备份的私钥
```

## 🔍 故障排除

### 常见问题

#### 1. OpenSSL未找到
```bash
# CentOS/RHEL
sudo yum install -y openssl openssl-devel

# Ubuntu/Debian
sudo apt-get install -y openssl libssl-dev
```

#### 2. 权限错误
```bash
# 设置SSL目录权限
chmod 700 ../../ssl/
chmod 600 ../../ssl/nginx.key
chmod 644 ../../ssl/nginx.crt
```

#### 3. 证书验证失败
```bash
# 验证证书
./manage_ssl.sh verify

# 查看证书详情
./manage_ssl.sh info

# 重新生成证书
./manage_ssl.sh renew
```

#### 4. nginx配置错误
```bash
# 测试nginx配置
../nginx_bin -t -c ../conf/nginx.conf

# 检查SSL证书路径
ls -la ../../ssl/
```

## 🧪 测试命令

### 验证HTTPS服务
```bash
# 测试本地HTTPS连接
curl -k https://localhost:8443

# 测试证书信息
openssl s_client -connect localhost:8443 -servername localhost

# 查看证书详情
openssl x509 -in ../../ssl/nginx.crt -text -noout
```

### 验证SAN扩展
```bash
# 查看SAN扩展信息
openssl x509 -in ../../ssl/nginx.crt -noout -text | grep -A 10 "Subject Alternative Name"
```

## 📚 更多信息

### SSL证书类型选择

#### 标准SSL证书
- 适用于单一域名/IP
- 配置简单
- 兼容性好

#### SAN扩展SSL证书（推荐）
- 支持多个域名和IP
- 更灵活的部署方式
- 符合现代SSL标准
- 适合开发和测试环境

### 证书更新策略
- 定期检查证书有效期: `./manage_ssl.sh check`
- 30天内到期会有提醒
- 生产环境建议使用正式CA证书

## 🔗 相关脚本

- `../start.sh` - 启动nginx服务
- `../stop.sh` - 停止nginx服务  
- `../restart.sh` - 重启nginx服务
- `../status.sh` - 查看nginx状态
- `../reload.sh` - 重载nginx配置

## ⚠️ 注意事项

1. **自签名证书**: 浏览器会显示安全警告，这是正常现象
2. **生产环境**: 建议使用正式CA签发的证书
3. **权限管理**: 私钥文件权限应设置为600
4. **备份重要**: 生成新证书前会自动备份现有证书
5. **配置同步**: 修改SSL配置后需要重新生成证书

## 📞 技术支持

如遇问题，请检查：
1. nginx是否正确安装并支持SSL模块
2. OpenSSL工具是否已安装
3. 文件权限是否正确设置
4. nginx配置文件是否正确引用SSL证书路径