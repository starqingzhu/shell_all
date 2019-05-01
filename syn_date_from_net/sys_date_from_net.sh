#! /bin/sh

#更新安装插件,安装ntpdate工具

echo -e "\n----------同步网络时间设置开始---------------"
ntp_var=`yum list installed | grep ntp.x86_64 |wc -l`
if [ $ntp_var -lt 1 ]
then
    yum -y install ntp
else
    echo "ntp 插件已安装"
fi

ntpdate_var=`yum list installed | grep ntpdate.x86_64 |wc -l`
if [ $ntpdate_var -lt 1 ]
then
    yum -y install ntpdate
else
    echo "ntpdate 插件已安装"
fi

# 修改时区
# 列出所有时区
# timedatectl list-timezones

dst_timezone_var="Asia/Shanghai"
cur_timezone_var=`timedatectl status | grep $dst_timezone_var |wc -l`
echo "cur_timezone_var=$cur_timezone_var"
if [ $cur_timezone_var -lt 1 ]
then
    timedatectl set-timezone $dst_timezone_var
else
    echo -e "当前时区已经是:$dst_timezone_var"
fi
#
#设置系统时间与网络时间同步
echo -e "\n同步中请稍后---->>>>>"
ntpdate cn.pool.ntp.org

#将系统时间写入硬件时间
echo -e "\n将系统时间写入硬件时间--->>>>"
hwclock --systohc

#查看系统时间
echo -e "\n查看系统时间------>>>>>"
timedatectl
echo -e "\n----------同步网络时间设置结束---------------\n"
