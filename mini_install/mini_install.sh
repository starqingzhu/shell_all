#!/bin/sh

#需要每次修改该主机名
CURHOSTNAME="jjplat"
#查看本机ip
echo "ip 地址:---------------------------------------->"
ip addr 

#找出那些包提供了
echo "安装ifconfig相关-------------------------------->"
yum whatprovides ifconfig
yum -y install net-tools

sleep 1
#安装编辑及编译工具
echo "安装gcc g++相关--------------------------------->"
yum -y install vim gcc gcc-c++ g++  lrzsz  unzip zip wget cmake git ntp ntpdate telnet mailx links

#参照修改静态ip文档
#修改hostname
#echo $HOSTNAME
echo "修改hostname相关-------------------------------->"
cat  /etc/hostname
echo $CURHOSTNAME > /etc/hostname
cat  /etc/hostname

#更新安装已有的软件最新版本以及安全升级
echo "更新系统软件相关-------------------------------->"
yum update && yum upgrade

#自动更新和升级
yum -y update && yum -y upgrade

#安装命令行web浏览器
echo "安装web浏览器相关-------------------------------->"
yum install links

#关闭防火墙
echo "关闭防火墙--------------------------------------->"
systemctl disable firewalld.service
#安装 Apache HTTP服务器
echo "安装Apache http服务器---------------------------->"
yum -y install httpd
systemctl restart httpd.service
systemctl enable httpd.service

#测试links
links 127.0.0.1
