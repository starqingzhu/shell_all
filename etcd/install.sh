#! /bin/sh

# 创建必要目录
# data 数据存储目录
# scripts 存放脚本目录
# bin 存放二进制文件目录
mkdir -p data scripts bin

# Download and install etcd version 3.5.24
wget https://github.com/etcd-io/etcd/releases/download/v3.5.24/etcd-v3.5.24-linux-amd64.tar.gz
tar -zxvf etcd-v3.5.24-linux-amd64.tar.gz
cd etcd-v3.5.24-linux-amd64

cp -rf etcd* ../bin/
cd ..


