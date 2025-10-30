# Akamai CDN Refresh Tool

🚀 一个功能强大的Akamai CDN缓存刷新工具，支持多平台编译和智能化构建发布流程。

## 📋 目录

- [特性](#特性)
- [项目结构](#项目结构)
- [快速开始](#快速开始)
- [构建](#构建)
- [发布打包](#发布打包)
- [使用方法](#使用方法)
- [配置](#配置)
- [平台支持](#平台支持)
- [开发指南](#开发指南)
- [故障排除](#故障排除)

## ✨ 特性

### 🔧 核心功能
- **多种刷新类型**：支持URL、目录、CPCode刷新
- **批量操作**：支持从文件批量读取刷新目标
- **预览模式**：刷新前预览操作内容
- **强制刷新**：bypass缓存强制刷新
- **智能验证**：自动验证API凭证和参数

### 🌍 跨平台支持
- **Windows**：64位 (Intel/AMD)、ARM64 (Surface Pro X等)
- **macOS**：Intel (x86_64)、Apple Silicon (M1/M2/M3/M4)
- **Linux**：64位 (Intel/AMD)、ARM64 (树莓派4等)、32位 (x86)

### 🛠️ 开发工具
- **交互式构建**：智能平台选择菜单
- **选择性编译**：按需编译特定平台，大幅提升效率
- **自动化发布**：一键生成多平台发布包
- **单平台优化**：简洁的单平台包结构

## 📁 项目结构

```
akamai/
├── conf/                           # 配置文件目录
│   ├── akamai.conf                 # API配置文件
│   ├── url.json                    # URL刷新配置
│   ├── urls.txt                    # URL列表
│   └── cpcodes.txt                 # CPCode列表
├── src/                            # 源代码目录
│   └── akamai_cdn_refresh.go       # 主程序源码
├── scripts/                        # 构建脚本目录
│   ├── build.sh                    # 本地平台构建
│   ├── build_cross_platform.sh     # 跨平台构建（交互式）
│   ├── release.sh                  # 发布打包脚本
│   └── test_refresh.sh             # 刷新测试脚本
├── dist/                           # 构建输出目录
└── release/                        # 发布包目录
```

## 🚀 快速开始

### 1. 环境要求

- **Go 1.19+**：用于编译源代码
- **Bash**：用于运行构建脚本
- **Git**：用于版本控制（可选）

### 2. 克隆项目

```bash
git clone <repository-url>
cd akamai
```

### 3. 配置API凭证

编辑 `conf/akamai.conf` 文件：

```ini
[default]
client_token = your_client_token
client_secret = your_client_secret
access_token = your_access_token
host = your_host.luna.akamaiapis.net
```

### 4. 构建程序

```bash
# 交互式构建（推荐）
bash scripts/build_cross_platform.sh

# 构建所有平台
bash scripts/build_cross_platform.sh -a

# 构建特定平台
bash scripts/build_cross_platform.sh windows-amd64
```

### 5. 运行程序

```bash
# Windows
cd dist && akamai_cdn_refresh_windows-amd64.exe --help

# macOS/Linux
cd dist && ./akamai_cdn_refresh_darwin-arm64 --help
```

## 🔨 构建

### 交互式构建（推荐）

```bash
bash scripts/build_cross_platform.sh
```

运行后会显示平台选择菜单：

```
请选择要编译的平台:

  1) Windows 64位 (windows-amd64)
  2) Windows ARM64 (windows-arm64)
  3) macOS Intel (darwin-amd64)
  4) macOS Apple Silicon (darwin-arm64)
  5) Linux 64位 (linux-amd64)
  6) Linux ARM64 (linux-arm64)
  7) Linux 32位 (linux-386)
  8) 所有Windows平台
  9) 所有macOS平台
 10) 所有Linux平台
 11) 所有平台
  0) 退出

请输入选项 (0-11):
```

### 命令行构建

```bash
# 构建所有平台（约2-3分钟）
bash scripts/build_cross_platform.sh -a

# 构建单个平台（约20-30秒）
bash scripts/build_cross_platform.sh windows-amd64

# 构建多个平台
bash scripts/build_cross_platform.sh windows-amd64 darwin-arm64

# 使用通配符
bash scripts/build_cross_platform.sh darwin-*      # 所有macOS平台
bash scripts/build_cross_platform.sh windows-*     # 所有Windows平台
bash scripts/build_cross_platform.sh linux-*       # 所有Linux平台

# 查看支持的平台
bash scripts/build_cross_platform.sh -l

# 查看帮助
bash scripts/build_cross_platform.sh -h
```

### 性能对比

| 构建类型 | 构建时间 | 输出大小 | 适用场景 |
|---------|---------|---------|---------|
| 单平台 | ~20-30秒 | ~6MB | 开发测试 |
| 平台组 | ~1-2分钟 | ~15-20MB | 目标平台组 |
| 全平台 | ~2-3分钟 | ~40MB | 完整发布 |

## 📦 发布打包

### 交互式打包（推荐）

```bash
bash scripts/release.sh
```

### 命令行打包

```bash
# 打包所有平台（平台包+完整包）
bash scripts/release.sh -a

# 只生成平台独立包
bash scripts/release.sh -p

# 只生成完整包
bash scripts/release.sh -f

# 打包特定平台
bash scripts/release.sh -p windows-amd64

# 打包平台组
bash scripts/release.sh -p darwin-*

# 查看可用平台
bash scripts/release.sh -l
```

### 发布包结构

#### 单平台包（简洁模式）
```
release/
├── akamai_cdn_refresh_windows-amd64/
│   ├── akamai.conf                    # 配置文件
│   ├── akamai_cdn_refresh.exe         # 可执行文件（简洁名称）
│   ├── PLATFORM_GUIDE.md             # 平台指南
│   └── QUICK_START.md                 # 快速开始
└── akamai_cdn_refresh_windows-amd64.zip
```

#### 多平台包（完整模式）
```
release/
├── akamai_cdn_refresh_v20241030_123456/              # 完整包
├── akamai_cdn_refresh_v20241030_123456_windows-amd64/
├── akamai_cdn_refresh_v20241030_123456_darwin-arm64/
└── ...
```

## 💻 使用方法

### 基本用法

```bash
# 刷新单个URL
./akamai_cdn_refresh --force https://cdn.example.com/style.css

# 预览模式（不执行实际刷新）
./akamai_cdn_refresh -n https://cdn.example.com/style.css

# 刷新目录
./akamai_cdn_refresh -d "/css/"

# 刷新CPCode
./akamai_cdn_refresh -c 1234567
```

### 批量操作

```bash
# 从文件批量刷新URL
./akamai_cdn_refresh -f urls.txt

# 从文件批量刷新目录
./akamai_cdn_refresh -f directories.txt

# 从文件批量刷新CPCode
./akamai_cdn_refresh -f cpcodes.txt
```

### 高级选项

```bash
# 强制刷新（bypass缓存）
./akamai_cdn_refresh --force https://cdn.example.com/app.js

# 指定配置文件
./akamai_cdn_refresh --config custom.conf https://example.com/

# 详细输出
./akamai_cdn_refresh -v https://example.com/

# 查看帮助
./akamai_cdn_refresh --help
```

## ⚙️ 配置

### API配置文件 (conf/akamai.conf)

```ini
[default]
client_token = akab-xxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxx
client_secret = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
access_token = akab-xxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxx
host = akab-xxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxx.luna.akamaiapis.net
```

### URL列表文件 (conf/urls.txt)

```
https://cdn.example.com/style.css
https://cdn.example.com/script.js
https://cdn.example.com/images/logo.png
```

### 目录列表文件 (conf/directories.txt)

```
/css/
/js/
/images/
```

### CPCode列表文件 (conf/cpcodes.txt)

```
1234567
1234568
1234569
```

## 🌍 平台支持

| 平台 | 架构 | 二进制文件名 | 描述 |
|------|------|-------------|------|
| Windows | x64 (Intel/AMD) | `akamai_cdn_refresh_windows-amd64.exe` | 标准Windows 64位 |
| Windows | ARM64 | `akamai_cdn_refresh_windows-arm64.exe` | Windows on ARM (Surface Pro X等) |
| macOS | x64 (Intel) | `akamai_cdn_refresh_darwin-amd64` | 基于Intel的Mac |
| macOS | ARM64 (Apple Silicon) | `akamai_cdn_refresh_darwin-arm64` | M1/M2/M3/M4 Mac |
| Linux | x64 (Intel/AMD) | `akamai_cdn_refresh_linux-amd64` | 标准Linux 64位 |
| Linux | ARM64 | `akamai_cdn_refresh_linux-arm64` | ARM64 Linux (树莓派4等) |
| Linux | x86 (32位) | `akamai_cdn_refresh_linux-386` | 传统32位Linux |

### 平台特定说明

#### Windows
```cmd
REM 下载并运行
cd dist
akamai_cdn_refresh_windows-amd64.exe --help
```

#### macOS
```bash
# 赋予执行权限并运行
cd dist
chmod +x akamai_cdn_refresh_darwin-arm64  # 或 darwin-amd64 用于Intel Mac
./akamai_cdn_refresh_darwin-arm64 --help
```

#### Linux
```bash
# 赋予执行权限并运行
cd dist
chmod +x akamai_cdn_refresh_linux-amd64  # 或其他Linux变体
./akamai_cdn_refresh_linux-amd64 --help
```

## 👨‍💻 开发指南

### 开发环境设置

1. **安装Go**：确保Go 1.19+已安装
2. **克隆仓库**：获取最新源代码
3. **配置API**：设置Akamai API凭证
4. **测试构建**：验证构建流程

### 源代码结构

```go
// src/akamai_cdn_refresh.go
package main

import (
    // 标准库
    "flag"
    "fmt"
    "os"
    
    // Akamai EdgeGrid库
    "github.com/akamai/AkamaiOPEN-edgegrid-golang/edgegrid"
)

func main() {
    // 主程序逻辑
}
```

### 添加新平台支持

在 `scripts/build_cross_platform.sh` 中添加新的平台目标：

```bash
declare -A targets=(
    # 现有平台...
    ["new-platform"]="goos goarch extension"
)

declare -A platform_descriptions=(
    # 现有描述...
    ["new-platform"]="新平台描述"
)
```

### 构建脚本自定义

可以通过修改构建脚本来自定义构建行为：

- **build.sh**：本地平台快速构建
- **build_cross_platform.sh**：跨平台构建主脚本
- **release.sh**：发布打包流程

## 🔧 故障排除

### 常见问题

#### 1. Go环境未找到
```
[ERROR] Go not found. Please install Go.
```
**解决方案**：安装Go 1.19+并确保在PATH中

#### 2. API认证失败
```
Error: Authentication failed
```
**解决方案**：
- 检查 `conf/akamai.conf` 中的凭证
- 确保API Client已在Akamai Control Center中激活
- 验证访问权限设置

#### 3. 构建失败
```
[FAIL] Failed: target
```
**解决方案**：
- 检查Go版本兼容性
- 确保有足够的磁盘空间
- 检查网络连接（下载依赖）

#### 4. 权限错误（Linux/macOS）
```
Permission denied
```
**解决方案**：
```bash
chmod +x akamai_cdn_refresh_platform
```

### 调试技巧

#### 启用详细输出
```bash
# 构建时启用详细输出
bash -x scripts/build_cross_platform.sh

# 程序运行时启用详细输出
./akamai_cdn_refresh -v https://example.com/
```

#### 检查构建状态
```bash
# 查看构建输出
ls -la dist/

# 检查文件大小
du -h dist/*

# 测试可执行文件
./dist/akamai_cdn_refresh_platform --version
```

#### 验证配置
```bash
# 测试API连接
./akamai_cdn_refresh -n https://example.com/test.txt

# 检查配置文件语法
cat conf/akamai.conf
```

### 性能优化建议

1. **选择性构建**：仅构建需要的平台
2. **使用SSD**：提高构建速度
3. **增加内存**：并行构建时有帮助
4. **网络优化**：确保稳定的网络连接

## 📞 支持与反馈

- **问题报告**：请在Issues中提交
- **功能请求**：欢迎提出改进建议
- **文档改进**：帮助完善文档

## 📄 许可证

本项目采用 [MIT License](LICENSE) 许可证。

## 🙏 致谢

感谢所有贡献者和Akamai社区的支持。

---

**最后更新**：2024年10月30日  
**版本**：v2.0.0  
**维护者**：sunbin