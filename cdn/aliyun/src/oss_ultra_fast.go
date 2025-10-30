package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
)

type UltraConfig struct {
	Endpoint        string
	AccessKeyID     string
	AccessKeySecret string
	BucketName      string
	LocalPath       string  // 支持文件或目录
	RemoteObject    string
	PartSize        int64
	Routines        int
	UseAggressive   bool
	IsDirectory     bool    // 是否为目录上传
	UploadCount     int     // 上传文件计数
	TotalFiles      int     // 总文件数
}

func main() {
	if len(os.Args) < 3 {
		showUltraUsage()
		return
	}

	config, err := parseUltraConfig()
	if err != nil {
		fmt.Printf("配置错误: %v\n", err)
		return
	}

	if err := uploadUltraFast(config); err != nil {
		fmt.Printf("上传失败: %v\n", err)
		os.Exit(1)
	}
}

func showUltraUsage() {
	fmt.Printf(`OSS极速上传工具 - 突破性能版本

用法: %s <本地文件/目录> <远程路径> [选项]

选项:
  -s SIZE     分片大小(MB)，默认1MB
  -r NUM      并发数，默认50
  -x          极限模式 (超高性能)
  -d          目录上传模式
  -h          帮助

示例:
  文件上传:
    %s video.mp4 media/video.mp4 -x
    %s file.zip backups/file.zip -s 1 -r 80 -x
  
  目录上传:
    %s ./src/ project/src/ -d
    %s ./build/ releases/v1.0/ -d -x

极限模式特点:
  🚀 1MB超小分片
  ⚡ 80并发连接
  💥 目标突破500KB/s
`, os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0])
}

func parseUltraConfig() (*UltraConfig, error) {
	config := &UltraConfig{
		LocalPath:     cleanPath(os.Args[1]),     // 清理路径
		RemoteObject:  cleanPath(os.Args[2]),     // 清理路径
		PartSize:      1024 * 1024, // 1MB
		Routines:      50,
		UseAggressive: false,
		IsDirectory:   false,
		UploadCount:   0,
		TotalFiles:    0,
	}

	for i := 3; i < len(os.Args); i++ {
		switch os.Args[i] {
		case "-s":
			if i+1 < len(os.Args) {
				if size, err := strconv.ParseInt(os.Args[i+1], 10, 64); err == nil {
					config.PartSize = size * 1024 * 1024
				}
				i++
			}
		case "-r":
			if i+1 < len(os.Args) {
				if routines, err := strconv.Atoi(os.Args[i+1]); err == nil {
					config.Routines = routines
				}
				i++
			}
		case "-x":
			config.UseAggressive = true
			config.PartSize = 1024 * 1024 // 强制1MB
			config.Routines = 80          // 极限并发
		case "-d":
			config.IsDirectory = true
		case "-h":
			showUltraUsage()
			os.Exit(0)
		}
	}

	// 检查路径是否为目录
	if stat, err := os.Stat(config.LocalPath); err == nil {
		if stat.IsDir() {
			config.IsDirectory = true
		}
	}

	if err := loadUltraOSSConfig(config); err != nil {
		return nil, err
	}

	return config, nil
}

// 清理Git Bash自动添加的路径前缀
func cleanPath(path string) string {
	// 移除Git Bash添加的前缀
	if strings.HasPrefix(path, "C:/Program Files/Git/") {
		path = strings.TrimPrefix(path, "C:/Program Files/Git")
	}
	if strings.HasPrefix(path, "/c/Program Files/Git/") {
		path = strings.TrimPrefix(path, "/c/Program Files/Git")
	}
	
	// 确保路径以正确的格式开始
	if strings.HasPrefix(path, "/") && !strings.HasPrefix(path, "//") {
		// Unix风格路径，保持不变
		return path
	}
	
	// 清理多余的斜杠
	path = strings.TrimPrefix(path, "/")
	
	return path
}

func loadUltraOSSConfig(config *UltraConfig) error {
	config.Endpoint = os.Getenv("OSS_ENDPOINT")
	config.AccessKeyID = os.Getenv("OSS_ACCESS_KEY_ID")
	config.AccessKeySecret = os.Getenv("OSS_ACCESS_KEY_SECRET")
	config.BucketName = os.Getenv("OSS_BUCKET")

	if config.AccessKeyID == "" {
		if err := loadUltraFromOSSUtilConfig(config); err != nil {
			return fmt.Errorf("无法获取OSS配置: %v", err)
		}
	}

	if config.Endpoint == "" {
		config.Endpoint = "oss-cn-hongkong.aliyuncs.com"
	}
	if config.BucketName == "" {
		config.BucketName = "oss-mh"
	}

	if config.AccessKeyID == "" || config.AccessKeySecret == "" {
		return fmt.Errorf("请设置OSS认证信息")
	}

	return nil
}

func loadUltraFromOSSUtilConfig(config *UltraConfig) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	configFile := filepath.Join(homeDir, ".ossutilconfig")
	content, err := os.ReadFile(configFile)
	if err != nil {
		return err
	}

	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "accessKeyId=") {
			config.AccessKeyID = strings.TrimPrefix(line, "accessKeyId=")
		} else if strings.HasPrefix(line, "accessKeySecret=") {
			config.AccessKeySecret = strings.TrimPrefix(line, "accessKeySecret=")
		} else if strings.HasPrefix(line, "endpoint=") {
			endpoint := strings.TrimPrefix(line, "endpoint=")
			endpoint = strings.TrimPrefix(endpoint, "http://")
			endpoint = strings.TrimPrefix(endpoint, "https://")
			config.Endpoint = endpoint
		}
	}

	return nil
}

func uploadUltraFast(config *UltraConfig) error {
	client, err := oss.New(config.Endpoint, config.AccessKeyID, config.AccessKeySecret)
	if err != nil {
		return fmt.Errorf("创建OSS客户端失败: %v", err)
	}

	bucket, err := client.Bucket(config.BucketName)
	if err != nil {
		return fmt.Errorf("获取bucket失败: %v", err)
	}

	if config.IsDirectory {
		return uploadDirectory(config, bucket)
	} else {
		return uploadSingleFile(config, bucket, config.LocalPath, config.RemoteObject)
	}
}

func uploadDirectory(config *UltraConfig, bucket *oss.Bucket) error {
	fmt.Printf("🚀 极速目录上传模式启动\n")
	fmt.Printf("目录: %s\n", config.LocalPath)
	fmt.Printf("目标: oss://%s/%s\n", config.BucketName, config.RemoteObject)

	if config.UseAggressive {
		fmt.Printf("💥 极限模式: %dMB分片, %d并发\n", 
			config.PartSize/1024/1024, config.Routines)
	}

	// 收集所有文件
	var files []string
	err := filepath.Walk(config.LocalPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			files = append(files, path)
		}
		return nil
	})

	if err != nil {
		return fmt.Errorf("扫描目录失败: %v", err)
	}

	config.TotalFiles = len(files)
	fmt.Printf("📁 发现 %d 个文件\n", config.TotalFiles)

	startTime := time.Now()

	// 上传所有文件
	for _, filePath := range files {
		relPath, err := filepath.Rel(config.LocalPath, filePath)
		if err != nil {
			return fmt.Errorf("计算相对路径失败: %v", err)
		}
		
		// 构建远程路径
		remotePath := filepath.Join(config.RemoteObject, relPath)
		remotePath = strings.ReplaceAll(remotePath, "\\", "/") // 确保使用正斜杠

		config.UploadCount++
		fmt.Printf("\n📤 [%d/%d] %s\n", config.UploadCount, config.TotalFiles, relPath)

		if err := uploadSingleFile(config, bucket, filePath, remotePath); err != nil {
			fmt.Printf("❌ 上传失败: %v\n", err)
			continue
		}
	}

	duration := time.Since(startTime)
	
	fmt.Printf("\n🎯 目录上传完成！\n")
	fmt.Printf("总文件: %d 个\n", config.TotalFiles)
	fmt.Printf("成功上传: %d 个\n", config.UploadCount)
	fmt.Printf("总耗时: %.2f秒\n", duration.Seconds())
	fmt.Printf("平均速度: %.2f 文件/秒\n", float64(config.UploadCount)/duration.Seconds())

	fmt.Printf("\nOSS目录: https://%s.%s/%s\n", 
		config.BucketName, config.Endpoint, config.RemoteObject)
	
	if config.BucketName == "oss-mh" {
		fmt.Printf("CDN目录: https://cdn-mh.hwrescdn.com/%s\n", config.RemoteObject)
	}

	return nil
}

func uploadSingleFile(config *UltraConfig, bucket *oss.Bucket, localFile, remoteObject string) error {
	fileInfo, err := os.Stat(localFile)
	if err != nil {
		return fmt.Errorf("文件不存在: %v", err)
	}

	fileSize := fileInfo.Size()
	
	if !config.IsDirectory {
		fmt.Printf("🚀 极速上传模式启动\n")
		fmt.Printf("文件: %s (%.2f MB)\n", localFile, float64(fileSize)/1024/1024)
		fmt.Printf("目标: oss://%s/%s\n", config.BucketName, remoteObject)

		if config.UseAggressive {
			fmt.Printf("💥 极限模式: %dMB分片, %d并发\n", 
				config.PartSize/1024/1024, config.Routines)
		}
	}

	startTime := time.Now()

	// 根据文件大小和模式选择策略
	if fileSize < 10*1024*1024 && !config.UseAggressive {
		if !config.IsDirectory {
			fmt.Printf("策略: 直接上传\n")
		}
		err = bucket.PutObjectFromFile(remoteObject, localFile)
	} else {
		if !config.IsDirectory {
			fmt.Printf("策略: 极速分片 (%dMB/%d并发)\n", 
				config.PartSize/1024/1024, config.Routines)
		}

		progress := &UltraProgressListener{
			fileSize:    fileSize,
			lastPrint:   time.Now(),
			isDirectory: config.IsDirectory,
		}

		err = bucket.UploadFile(remoteObject, localFile, config.PartSize,
			oss.Routines(config.Routines),
			oss.Progress(progress))
	}

	if err != nil {
		return fmt.Errorf("上传过程失败: %v", err)
	}

	duration := time.Since(startTime)
	speed := float64(fileSize) / duration.Seconds() / 1024 / 1024

	if !config.IsDirectory {
		fmt.Printf("\n🎯 极速上传完成！\n")
		fmt.Printf("耗时: %.2f秒\n", duration.Seconds())
		fmt.Printf("速度: %.2f MB/s (%.0f KB/s)\n", speed, speed*1024)

		// 性能分析
		expectedSpeed := 0.15 // ossutil基准速度
		improvement := speed / expectedSpeed
		
		if improvement > 3 {
			fmt.Printf("🏆 卓越! 比ossutil快 %.1fx\n", improvement)
		} else if improvement > 2 {
			fmt.Printf("🔥 优秀! 比ossutil快 %.1fx\n", improvement)
		} else if improvement > 1.5 {
			fmt.Printf("✅ 良好! 比ossutil快 %.1fx\n", improvement)
		} else {
			fmt.Printf("⚠️  提升有限，仅比ossutil快 %.1fx\n", improvement)
			fmt.Printf("建议: 使用极限模式 -x\n")
		}

		fmt.Printf("\nOSS地址: https://%s.%s/%s\n", 
			config.BucketName, config.Endpoint, remoteObject)
		
		if config.BucketName == "oss-mh" {
			fmt.Printf("CDN地址: https://cdn-mh.hwrescdn.com/%s\n", remoteObject)
		}
	}

	return nil
}

type UltraProgressListener struct {
	fileSize     int64
	lastPrint    time.Time
	printMutex   sync.Mutex
	isDirectory  bool
}

func (l *UltraProgressListener) ProgressChanged(event *oss.ProgressEvent) {
	switch event.EventType {
	case oss.TransferStartedEvent:
		if !l.isDirectory {
			fmt.Printf("⚡ 开始传输...\n")
		}
		l.lastPrint = time.Now()
	case oss.TransferDataEvent:
		l.printMutex.Lock()
		now := time.Now()
		
		// 在目录模式下降低进度输出频率
		interval := 1 * time.Second
		if l.isDirectory {
			interval = 3 * time.Second
		}
		
		if now.Sub(l.lastPrint) > interval && l.fileSize > 0 {
			percent := float64(event.ConsumedBytes) / float64(l.fileSize) * 100
			mbUploaded := float64(event.ConsumedBytes) / 1024 / 1024
			mbTotal := float64(l.fileSize) / 1024 / 1024
			
			if l.isDirectory {
				fmt.Printf("   进度: %.1f%% (%.2f/%.2f MB)\n", percent, mbUploaded, mbTotal)
			} else {
				fmt.Printf("\r💫 进度: %.1f%% (%.2f/%.2f MB)", percent, mbUploaded, mbTotal)
			}
			l.lastPrint = now
		}
		l.printMutex.Unlock()
	case oss.TransferCompletedEvent:
		if !l.isDirectory {
			fmt.Printf("\n🚀 传输完成\n")
		}
	case oss.TransferFailedEvent:
		if !l.isDirectory {
			fmt.Printf("\n💥 传输失败\n")
		}
	}
}
