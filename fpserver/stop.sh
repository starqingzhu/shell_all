#! /usr/sh

mystop
rdstop
ps -ef | grep etcd | grep -v grep | awk '{print $2}' | xargs sudo kill -9
srbstop
