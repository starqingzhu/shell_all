#! /usr/sh

#卸载旧版本
yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine

#安装docker依赖工具
yum install -y yum-utils device-mapper-persistent-data lvm2

#设置稳定的存储库
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

#安装docker
yum install -y docker-ce

#启动docker服务
systemctl start docker.service

#检查docker安装结果
docker info
