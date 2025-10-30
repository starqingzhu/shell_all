#!/usr/bin/env bash

# 刷新url  测试脚本
../dist/akamai_cdn_refresh_windows_amd64.exe https://cdn-mh.hwrescdn.com/test/build_ultra.sh
../dist/akamai_cdn_refresh_windows_amd64.exe https://cdn-mh.hwrescdn.com/test1/build_ultra.sh

# 刷新目录  测试脚本
../dist/akamai_cdn_refresh_windows_amd64.exe -d "/test/"
../dist/akamai_cdn_refresh_windows_amd64.exe -d "/test1/"

# 批量刷新目录  测试脚本
../dist/akamai_cdn_refresh_windows_amd64.exe -f ../conf/directories.txt

# 批量刷新CP Code  测试脚本
../dist/akamai_cdn_refresh_windows_amd64.exe -c 1892943
../dist/akamai_cdn_refresh_windows_amd64.exe -f ../conf/cpcodes.txt