#!/bin/bash


echo "在终端中执行以下命令安装 MySQL 的 yum 源：......"
sudo rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm

echo "安装工机包 ......"
sudo yum install wget curl

echo "安装mysql服务器"
sudo yum install mysql-server


# 启动mysql
# systemctl start mysqld
# 设置开机启动
# systemctl enable mysqld

#输出root 初始密码
sudo grep 'temporary password' /var/log/mysqld.log


# 更新新密码
#ALTER USER 'root'@'localhost' IDENTIFIED BY 'Ab@123456'
