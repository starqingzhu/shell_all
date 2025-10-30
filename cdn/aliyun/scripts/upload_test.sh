#!/usr/bin/env bash

# 上传文件功能测试脚本
../dist/oss_ultra_fast build_ultra.sh test/build_ultra.sh -s 0.5 -r 80
../dist/oss_ultra_fast build_ultra.sh test1/build_ultra.sh -s 0.5 -r 80

# 上传目录功能测试
../dist/oss_ultra_fast ../scripts/ test/scripts/ -d -x
