#! /usr/bash

# 安装mysql
brew install mysql
# 设置开机启动
sudo cp /usr/local/opt/mysql/homebrew.mxcl.mysql.plist  /Library/LaunchAgents/
cd /Library/LaunchAgents/
sudo launchctl load homebrew.mxcl.mysql.plist
cd ~
#查看系统系统项列表
launchctl list
#启动mysql
mysql.server start


#2. 安装redis
brew search redis
brew install redis

echo 'export PATH="/usr/local/opt/redis/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
#启动redis
brew services start redis


#3. 安装etcd
brew search etcd
brew install etcd
etcd &

#4. 安装rabbitmq
brew search rabbitmq
brew install rabbitmq
# 启动rabbitmq
brew services start rabbitmq

#5 安装python3.7.6