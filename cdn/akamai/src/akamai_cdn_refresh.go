package main

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// AkamaiConfig Akamai配置
type AkamaiConfig struct {
	ClientToken  string // Akamai API Client Token
	ClientSecret string // Akamai API Client Secret
	AccessToken  string // Akamai API Access Token
	BaseURL      string // Akamai API基础URL
	CDNDomain    string // CDN域名，用于目录刷新时构造完整URL
	Verbose      bool   // 详细模式
	DryRun       bool   // 预览模式
}

// AkamaiResponse Akamai API响应
type AkamaiResponse struct {
	PurgeID          string `json:"purgeId"`
	SupportID        string `json:"supportId"`
	HTTPStatus       int    `json:"httpStatus"`
	Detail           string `json:"detail"`
	EstimatedSeconds int    `json:"estimatedSeconds"`
}

// 规范化路径 - 确保目录路径以Unix风格保存
func normalizePath(path string) string {
	// 如果是URL，直接返回
	if strings.HasPrefix(path, "http://") || strings.HasPrefix(path, "https://") {
		return path
	}

	// 转换为Unix风格的路径
	normalized := filepath.ToSlash(path)

	// 对于CDN目录路径，不要进行文件系统路径转换
	// 只需要确保使用Unix风格的斜杠

	// 如果已经是以/开头的路径，直接使用（这是CDN目录路径）
	if strings.HasPrefix(normalized, "/") {
		return normalized
	}

	// 如果是Windows的绝对路径（如C:/...），提取为CDN路径格式
	if len(normalized) >= 3 && normalized[1] == ':' {
		// 提取盘符后的部分作为相对路径
		parts := strings.Split(normalized, "/")
		if len(parts) > 2 {
			normalized = "/" + strings.Join(parts[2:], "/")
		}
	} else {
		// 确保目录路径以/开头
		normalized = "/" + normalized
	}

	return normalized
}

// 生成EdgeGrid认证头
func generateEdgeGridAuth(method, urlStr, body, clientToken, accessToken, clientSecret, host string) string {
	timestamp := time.Now().UTC().Format("20060102T15:04:05+0000")
	nonce := generateNonce()

	parsedURL, _ := url.Parse(urlStr)
	msgPath := parsedURL.EscapedPath()
	if parsedURL.RawQuery != "" {
		msgPath = fmt.Sprintf("%s?%s", msgPath, parsedURL.RawQuery)
	}

	// 正确计算content hash
	hasher := sha256.New()
	hasher.Write([]byte(body))
	contentHash := base64.StdEncoding.EncodeToString(hasher.Sum(nil))

	authHeader := fmt.Sprintf("EG1-HMAC-SHA256 client_token=%s;access_token=%s;timestamp=%s;nonce=%s;", clientToken, accessToken, timestamp, nonce)

	msgData := []string{
		method,
		"https",
		host,
		msgPath,
		"",
		contentHash,
		authHeader,
	}

	msg := strings.Join(msgData, "\t")

	// Debug信息 (可选)
	if os.Getenv("DEBUG") == "1" {
		fmt.Printf("Debug: timestamp: %s\n", timestamp)
		fmt.Printf("Debug: nonce: %s\n", nonce)
		fmt.Printf("Debug: msgPath: %s\n", msgPath)
		fmt.Printf("Debug: contentHash: %s\n", contentHash)
		fmt.Printf("Debug: message to sign: %q\n", msg)
	}

	signingKey := hmacSha256(timestamp, clientSecret)
	signature := hmacSha256(msg, signingKey)

	if os.Getenv("DEBUG") == "1" {
		fmt.Printf("Debug: signingKey: %s\n", signingKey)
		fmt.Printf("Debug: signature: %s\n", signature)
	}

	finalAuth := fmt.Sprintf("EG1-HMAC-SHA256 client_token=%s;access_token=%s;timestamp=%s;nonce=%s;signature=%s",
		clientToken, accessToken, timestamp, nonce, signature)

	if os.Getenv("DEBUG") == "1" {
		fmt.Printf("Debug: Final auth header: %s\n", finalAuth)
	}

	return finalAuth
}

func generateNonce() string {
	// 使用UUID格式的nonce，更符合Akamai标准
	return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x",
		time.Now().Unix()&0xffffffff,
		time.Now().Nanosecond()&0xffff,
		0xe000|(time.Now().Nanosecond()>>16)&0x0fff,
		0x8000|(time.Now().Nanosecond()>>8)&0x3fff,
		time.Now().UnixNano()&0xffffffffffff)
}

func hmacSha256(data, key string) string {
	h := hmac.New(sha256.New, []byte(key))
	h.Write([]byte(data))
	return base64.StdEncoding.EncodeToString(h.Sum(nil))
}

// 刷新Akamai CDN缓存 (支持URL和目录路径)
func refreshAkamaiCDN(config *AkamaiConfig, items []string, refreshType, contentType string) error {
	if len(items) == 0 {
		return fmt.Errorf("没有指定要刷新的内容")
	}

	var requestData map[string]interface{}
	var apiURL string
	var endpoint string

	if contentType == "cpcode" {
		fmt.Printf("🔢 准备刷新 %d 个CPCode\n", len(items))
		requestData = map[string]interface{}{
			"objects": items,
			"type":    refreshType,
		}
		endpoint = "/ccu/v3/invalidate/cpcode/production"
		if refreshType == "remove" {
			endpoint = "/ccu/v3/remove/cpcode/production"
		}
		apiURL = config.BaseURL + endpoint
	} else {
		// 规范化所有路径，对于目录路径转换为完整URL
		normalizedItems := make([]string, len(items))
		for i, item := range items {
			normalized := normalizePath(item)
			if contentType == "directory" && !strings.HasPrefix(normalized, "http") {
				if config.CDNDomain != "" {
					normalizedItems[i] = strings.TrimSuffix(config.CDNDomain, "/") + normalized
				} else {
					return fmt.Errorf("目录刷新需要在配置文件中设置CDN_DOMAIN")
				}
			} else {
				normalizedItems[i] = normalized
			}
		}
		requestData = map[string]interface{}{
			"objects": normalizedItems,
			"type":    refreshType,
		}
		endpoint = "/ccu/v3/invalidate/url/production"
		if refreshType == "remove" {
			endpoint = "/ccu/v3/remove/url/production"
		}
		apiURL = config.BaseURL + endpoint
	}

	jsonData, err := json.Marshal(requestData)
	if err != nil {
		return fmt.Errorf("构造请求数据失败: %v", err)
	}

	// 预览模式
	if config.DryRun {
		fmt.Printf("🔍 预览模式 - 不会实际执行刷新\n")
		fmt.Printf("📡 API URL: %s\n", apiURL)
		fmt.Printf("📋 请求数据: %s\n", string(jsonData))
		return nil
	}

	// 确认执行
	if !config.Verbose {
		if contentType == "directory" {
			fmt.Printf("确认执行Akamai CDN目录强制刷新? [y/N]: ")
		} else {
			fmt.Printf("确认执行Akamai CDN强制刷新? [y/N]: ")
		}
		var confirm string
		fmt.Scanln(&confirm)
		if strings.ToLower(confirm) != "y" && strings.ToLower(confirm) != "yes" {
			fmt.Printf("❌ 用户取消操作\n")
			return nil
		}
	}

	fmt.Printf("🚀 开始执行Akamai CDN刷新...\n")
	if config.Verbose {
		fmt.Printf("📡 API URL: %s\n", apiURL)
		fmt.Printf("📋 请求数据: %s\n", string(jsonData))
	}

	// 创建HTTP请求
	req, err := http.NewRequest("POST", apiURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("创建请求失败: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	baseURL, err := url.Parse(config.BaseURL)
	if err != nil {
		return fmt.Errorf("解析Akamai Base URL失败: %v", err)
	}

	req.Header.Set("Host", baseURL.Host)

	authHeader := generateEdgeGridAuth(req.Method, apiURL, string(jsonData),
		config.ClientToken, config.AccessToken, config.ClientSecret, baseURL.Host)
	req.Header.Set("Authorization", authHeader)

	if config.Verbose {
		fmt.Printf("🔐 Authorization: %s\n", authHeader)
	}

	client := &http.Client{Timeout: 30 * time.Second}

	fmt.Printf("📤 发送刷新请求...\n")
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("请求失败: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取响应失败: %v", err)
	}

	if config.Verbose {
		fmt.Printf("📥 HTTP状态: %d\n", resp.StatusCode)
		fmt.Printf("📥 响应内容: %s\n", string(body))
	}

	// 处理响应
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		var response AkamaiResponse
		if err := json.Unmarshal(body, &response); err != nil {
			fmt.Printf("⚠️  解析响应失败，但请求可能成功: %v\n", err)
		} else {
			fmt.Printf("✅ Akamai CDN刷新任务提交成功!\n")
			if response.PurgeID != "" {
				fmt.Printf("🆔 任务ID: %s\n", response.PurgeID)
			}
			if response.EstimatedSeconds > 0 {
				fmt.Printf("⏰ 预计生效时间: %d 秒\n", response.EstimatedSeconds)
			} else {
				fmt.Printf("⏰ 预计生效时间: 5-10 分钟\n")
			}

			fmt.Printf("\n📋 已提交刷新的内容:\n")
			for _, item := range items {
				fmt.Printf("  ✓ %s\n", item)
			}

			// 新增简明日志
			fmt.Printf("[刷新成功] 类型: %s, 内容: %s, 数量: %d, 任务ID: %s\n", refreshType, contentType, len(items), response.PurgeID)
		}
	} else if resp.StatusCode == 401 && strings.Contains(string(body), "Inactive client token") {
		fmt.Printf("❌ API Client未激活\n")
		fmt.Printf("\n🔑 您的API Client Token: %s\n", config.ClientToken)
		fmt.Printf("📊 状态: INACTIVE (需要激活)\n")
		fmt.Printf("\n🎯 激活步骤:\n")
		fmt.Printf("1. 访问: https://control.akamai.com/\n")
		fmt.Printf("2. 登录您的Akamai账户\n")
		fmt.Printf("3. 导航到: Identity & Access Management > API Clients\n")
		fmt.Printf("4. 搜索: %s\n", config.ClientToken)
		fmt.Printf("5. 点击进入详情页面\n")
		fmt.Printf("6. 点击 'Activate' 或 'Enable' 按钮\n")
		fmt.Printf("7. 确认包含 CCU (Content Control Utility) 权限\n")
		fmt.Printf("8. 保存更改\n")
		fmt.Printf("\n🧪 激活后验证:\n")
		fmt.Printf("./akamai_cdn_refresh_dir.exe --force %s\n", items[0])
		fmt.Printf("\n💡 技术分析: 工具本身运行正常，仅需激活API Client\n")
		return fmt.Errorf("API Client未激活，请按上述步骤激活后重试")
	} else {
		return fmt.Errorf("刷新失败: HTTP %d - %s", resp.StatusCode, string(body))
	}

	return nil
}

// 加载配置文件
func loadAkamaiConfigFromFile() (*AkamaiConfig, error) {
	// 优先尝试 ../conf/akamai.conf，其次 ./akamai.conf
	var configPath string
	if _, err := os.Stat("../conf/akamai.conf"); err == nil {
		configPath = "../conf/akamai.conf"
	} else if _, err := os.Stat("conf/akamai.conf"); err == nil {
		configPath = "conf/akamai.conf"
	} else if _, err := os.Stat("./akamai.conf"); err == nil {
		configPath = "./akamai.conf"
	} else {
		return nil, fmt.Errorf("找不到配置文件（../conf/akamai.conf、conf/akamai.conf、./akamai.conf 均不存在）")
	}

	content, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("读取配置文件失败: %v", err)
	}

	config := &AkamaiConfig{}
	lines := strings.Split(string(content), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		if strings.Contains(line, "=") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) != 2 {
				continue
			}

			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])

			// 移除引号
			if len(value) >= 2 && ((value[0] == '"' && value[len(value)-1] == '"') ||
				(value[0] == '\'' && value[len(value)-1] == '\'')) {
				value = value[1 : len(value)-1]
			}

			switch key {
			case "AKAMAI_CLIENT_TOKEN":
				config.ClientToken = value
			case "AKAMAI_CLIENT_SECRET":
				config.ClientSecret = value
			case "AKAMAI_ACCESS_TOKEN":
				config.AccessToken = value
			case "AKAMAI_BASE_URL":
				config.BaseURL = value
			case "CDN_DOMAIN":
				config.CDNDomain = value
			}
		}
	}

	// 验证必需的配置
	if config.ClientToken == "" {
		return nil, fmt.Errorf("配置文件中缺少AKAMAI_CLIENT_TOKEN")
	}
	if config.ClientSecret == "" {
		return nil, fmt.Errorf("配置文件中缺少AKAMAI_CLIENT_SECRET")
	}
	if config.AccessToken == "" {
		return nil, fmt.Errorf("配置文件中缺少AKAMAI_ACCESS_TOKEN")
	}
	if config.BaseURL == "" {
		return nil, fmt.Errorf("配置文件中缺少AKAMAI_BASE_URL")
	}

	fmt.Printf("✅ 已从配置文件加载Akamai配置: %s\n", configPath)
	return config, nil
}

// 从文件读取URL列表或目录路径列表
func loadItemsFromFile(filename string) ([]string, string, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return nil, "", fmt.Errorf("读取文件失败: %v", err)
	}

	lines := strings.Split(string(content), "\n")
	var items []string
	contentType := "url"

	for i, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// 检测内容类型
		if strings.HasPrefix(line, "http://") || strings.HasPrefix(line, "https://") {
			contentType = "url"
		} else if strings.HasPrefix(line, "/") {
			contentType = "directory"
		} else if _, err := strconv.Atoi(line); err == nil {
			contentType = "cpcode"
		} else {
			return nil, "", fmt.Errorf("第%d行格式错误: %s (应该是URL、以/开头的目录路径或纯数字CPCode)", i+1, line)
		}

		items = append(items, line)
	}

	return items, contentType, nil
}

// 显示使用帮助
func showUsage() {
	fmt.Printf(`🌐 Akamai CDN强制刷新工具 (支持目录路径)

用法: 
  %s [选项] <URL1> [URL2] [URL3] ...
  %s [选项] -f <文件路径>
  %s [选项] -d <目录路径1> [目录路径2] ...
  %s [选项] -c <CPCode1> [CPCode2] ...

选项:
  -h, --help     显示此帮助信息
  -v, --verbose  详细模式，显示详细的API调用信息
  -n, --dry-run  预览模式，不实际执行刷新
  -f, --file     从文件读取URL或目录路径列表
  -d, --dir      刷新目录路径 (目录刷新)
  -c, --cpcode   按CPCode刷新 (支持多个)
  -t, --type     刷新类型: delete (默认，invalidate) 或 remove (purge)
  --force        强制执行，跳过确认提示

刷新类型说明:
  URL刷新        刷新指定的具体文件URL
  目录刷新       刷新指定目录路径下的所有内容
  CPCode刷新     按指定CPCode刷新全站内容

环境变量:
  配置文件: akamai.conf
  AKAMAI_CLIENT_TOKEN    Akamai API Client Token
  AKAMAI_CLIENT_SECRET   Akamai API Client Secret  
  AKAMAI_ACCESS_TOKEN    Akamai API Access Token
  AKAMAI_BASE_URL        Akamai API Base URL

示例:
  # 刷新单个URL
  %s https://cdn-mh.hwrescdn.com/test.css

  # 刷新多个URL (详细模式)
  %s -v https://cdn-mh.hwrescdn.com/test.css https://cdn-mh.hwrescdn.com/test.js

  # 刷新目录路径 (重要：支持目录名而不是CP Code!)
  %s -d /static/css/

  # 刷新多个目录
  %s -d /static/css/ /static/js/

  # 从文件批量刷新URL
  %s -f urls.txt

  # 从文件批量刷新目录
  %s -f directories.txt

  # 按CPCode刷新
  %s -c 1892943

  # 从文件批量刷新CPCode
  %s -f cpcodes.txt

  # 预览模式 (不实际执行)
  %s -n https://cdn-mh.hwrescdn.com/test.css

  # 强制执行 (跳过确认)
  %s --force https://cdn-mh.hwrescdn.com/test.css

优势:
  ✅ 支持目录名直接刷新 (不需要查找CP Code)
  ✅ 自动检测URL和目录类型
  ✅ 批量文件处理
  ✅ 详细的错误提示和激活指导
  ✅ 自动路径规范化处理

注意事项:
  📌 目录路径会自动规范化为Unix风格 (/static/css/)
  📌 支持Windows和Unix路径格式输入
  📌 路径参数建议使用双引号包围: -d "/static/css/"
`, os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0])
}

func main() {
	fmt.Println("🌐 Akamai CDN强制刷新工具")
	args := os.Args[1:]
	if len(args) == 0 {
		showUsage()
		os.Exit(1)
	}

	var (
		items       []string
		dryRun      bool
		refreshType = "delete"
		filename    string
		contentType = "url"
	)

	// 解析参数
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch arg {
		case "-h", "--help":
			showUsage()
			os.Exit(0)
		case "-n", "--dry-run": // 预览模式
			dryRun = true
		case "-t", "--type":
			if i+1 >= len(args) {
				fmt.Printf("❌ 错误: -t/--type 需要指定刷新类型\n")
				os.Exit(1)
			}
			refreshType = args[i+1]
			if refreshType != "delete" && refreshType != "remove" {
				fmt.Printf("❌ 错误: 刷新类型必须是 delete 或 remove\n")
				os.Exit(1)
			}
			i++
		case "-d", "--dir":
			contentType = "directory"
			// 后续的参数都被当作目录路径处理
			for i+1 < len(args) && !strings.HasPrefix(args[i+1], "-") {
				i++
				items = append(items, args[i])
			}
		case "-f", "--file":
			if i+1 >= len(args) {
				fmt.Printf("❌ 错误: -f/--file 需要指定文件路径\n")
				os.Exit(1)
			}
			filename = args[i+1]
			i++
		case "-c", "--cpcode":
			contentType = "cpcode"
			items = nil // 清空items，避免混入其他参数
			for i+1 < len(args) && !strings.HasPrefix(args[i+1], "-") {
				next := args[i+1]
				if _, err := strconv.Atoi(next); err == nil {
					i++
					items = append(items, next)
				} else {
					break
				}
			}
		default:
			// 跳过所有以-开头的参数（如-c、-d、-f等）
			if strings.HasPrefix(arg, "-") {
				continue
			}
			// 判断是否是URL或目录路径
			if strings.HasPrefix(arg, "http://") || strings.HasPrefix(arg, "https://") {
				items = append(items, arg)
			} else if strings.HasPrefix(arg, "/") {
				// 以 / 开头的认为是目录路径
				contentType = "directory"
				items = append(items, arg)
			} else {
				items = append(items, arg)
			}
		}
	}

	// 从文件读取URL/目录路径
	if filename != "" {
		if len(items) > 0 {
			fmt.Printf("❌ 错误: 不能同时指定内容和文件\n")
			os.Exit(1)
		}
		fileItems, detectedType, err := loadItemsFromFile(filename)
		if err != nil {
			fmt.Printf("❌ 错误: %v\n", err)
			os.Exit(1)
		}
		items = fileItems
		contentType = detectedType
	}

	// 验证有内容需要刷新
	if len(items) == 0 {
		if contentType == "directory" {
			fmt.Printf("❌ 错误: 请指定要刷新的目录路径或使用 -f 指定文件\n")
		} else if contentType == "cpcode" {
			fmt.Printf("❌ 错误: 请指定要刷新的CPCode或使用 -f 指定文件\n")
		} else {
			fmt.Printf("❌ 错误: 请指定要刷新的URL或使用 -f 指定文件\n")
		}
		showUsage()
		os.Exit(1)
	}

	// 加载配置
	config, err := loadAkamaiConfigFromFile()
	if err != nil {
		fmt.Printf("❌ 配置错误: %v\n", err)
		fmt.Printf("\n💡 提示: 请创建akamai.conf文件:\n")
		fmt.Printf("  AKAMAI_CLIENT_TOKEN=\"your-client-token\"\n")
		fmt.Printf("  AKAMAI_CLIENT_SECRET=\"your-client-secret\"\n")
		fmt.Printf("  AKAMAI_ACCESS_TOKEN=\"your-access-token\"\n")
		fmt.Printf("  AKAMAI_BASE_URL=\"https://your-instance.luna.akamaiapis.net\"\n")
		os.Exit(1)
	}

	config.Verbose = true // 始终详细输出，且跳过交互
	config.DryRun = dryRun

	// 调用刷新逻辑
	if err := refreshAkamaiCDN(config, items, refreshType, contentType); err != nil {
		fmt.Printf("❌ 刷新失败: %v\n", err)
		os.Exit(1)
	}
}
