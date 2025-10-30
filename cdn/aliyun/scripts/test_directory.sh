#!/bin/bash

# 目录上传测试脚本

cd "$(dirname "$0")/.."

echo "🧪 目录上传功能测试"
echo "===================="

# 创建测试目录
test_dir="testpack/dir_test"
mkdir -p "$test_dir/subdir1"
mkdir -p "$test_dir/subdir2"

# 创建一些测试文件
echo "Test file 1" > "$test_dir/file1.txt"
echo "Test file 2" > "$test_dir/file2.txt"
echo "Subdir file 1" > "$test_dir/subdir1/sub1.txt"
echo "Subdir file 2" > "$test_dir/subdir2/sub2.txt"

# 复制一个二进制文件
if [ -f "testpack/MH_Android_Debug.apk" ]; then
    cp "testpack/MH_Android_Debug.apk" "$test_dir/test.apk"
fi

echo "📁 创建测试目录完成: $test_dir"
echo "文件列表:"
find "$test_dir" -type f -exec ls -lh {} \;

echo ""
echo "🚀 开始目录上传测试..."
echo ""

# 测试标准模式目录上传
echo "=== 标准模式目录上传 ==="
./dist/oss_ultra_fast "$test_dir" "test/dir_upload/standard" -d || echo "❌ 标准模式失败"

echo ""
echo "=== 极限模式目录上传 ==="  
./dist/oss_ultra_fast "$test_dir" "test/dir_upload/extreme" -d -x || echo "❌ 极限模式失败"

echo ""
echo "=== 单个文件测试 ==="
./dist/oss_ultra_fast "$test_dir/file1.txt" "test/single_file.txt" || echo "❌ 单文件测试失败"

echo ""
echo "✅ 目录上传测试完成"
echo "可以在OSS控制台查看上传结果："
echo "  - test/dir_upload/standard/"
echo "  - test/dir_upload/extreme/"
echo "  - test/single_file.txt"

# 清理测试目录
echo ""
read -p "是否删除测试目录? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$test_dir"
    echo "🗑️  测试目录已删除"
fi