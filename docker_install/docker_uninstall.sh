#! /usr/sh

#卸载docker

#查询所有的安装包
yum list installed | grep docker

#删除所有安装包
yum remove -y docker-ce
yum remove -y docker-ce-cli
yum remove -y containerd.io.x86_64

#删除镜像文件
rm -rf /var/lib/docker
rm -rf /var/lib/docker*
