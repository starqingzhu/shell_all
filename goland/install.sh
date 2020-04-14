#! /bin/sh

#更新brew 安装graphviz
brew install graphviz
#检验graphviz 是否安装成功，可以用命令 dot --help 如果弹出使用说明，则安装成功，否则失败
dot --help


#安装go-callvis
go get -u github.com/TrueFurby/go-callvis
#cd $GOPATH/src/github.com/TrueFurby/go-callvis && make


