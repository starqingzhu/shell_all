#!/bin/bash

path_var="/var/log/ip_cache/"
file_var="ip_cache"
ip_cache_file=$path_var$file_var'_file.txt'
ip_cache_log=$path_var$file_var'_log.txt'

echo -e "所需文件list:\n    ip_cache_file="$ip_cache_file"\n    ip_cache_log="$ip_cache_log

if [ ! -d $path_var ]
then
    echo "mkdir -p $path_var"
    mkdir -p $path_var
else
    echo "$path_var 存在"
fi

if [ ! -f $ip_cache_file ]
then
    echo "touch $ip_cache_file"
    touch $ip_cache_file
    echo "touch $ip_cache_log"
    touch $ip_cache_log
fi

#ipaddr_new=`curl ifconfig.me`
ipaddr_new=`curl http://members.3322.org/dyndns/getip`
ipaddr_old=`cat $ip_cache_file`

date_var=`date +%Y/%m/%d-%H:%M:%S`
echo $date_var" new:"$ipaddr_new"  old:"$ipaddr_old

if [ ! $ipaddr_old ]||[ $ipaddr_new != $ipaddr_old ]
then
    recver="3277364630@qq.com"
    mail_title="家庭公网地址更改为:"$ipaddr_new
    mail_text=$date_var" new:"$ipaddr_new"  old:"$ipaddr_old

    echo "$mail_text"  | mail -v -s "$mail_title"  $recver
    echo "$ipaddr_new" > $ip_cache_file
    echo $mail_text >> $ip_cache_log
else
    echo "ip正常无变化"
fi
