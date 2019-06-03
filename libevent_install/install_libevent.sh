#! /usr/bin

# date:2019-06-03
# author:sunbin

OUT_DIR=./net/
FILE_NAME=libevent-2.1.10-stable
APPEND_NAME=.tar.gz

#获取源码
wget -O $OUT_DIR$FILE_NAME$APPEND_NAME  https://github.com/libevent/libevent/releases/download/release-2.1.10-stable/libevent-2.1.10-stable.tar.gz

cd $OUT_DIR

tar -zxvf $FILE_NAME$APPEND_NAME

cd $FILE_NAME

./configure --prefix=/usr
make
make verify

# 成功后会在/usr/lib下发现libevent相关库文件
make install 
ldconfig
