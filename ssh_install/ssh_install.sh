#!/bin/bash

#ssh 免密设置

param_min=1
param_max=1

echo "命令行执行语句:"$*
if [ $# -lt $param_min  ] || [ $# -gt $param_max  ]
then
    echo "参数个数异常:[$param_min~$param_max]"
    exit 1
fi

#检测是否安装ssh服务
ssh_num_min=2
ssh_num=`yum list installed | grep ssh |wc -l`
echo -e "ssh_num=$ssh_num"
if [ $ssh_num -gt $ssh_num_min ]
then
    echo "ssh 已经安装"
else
    echo "ssh 开始安装"
    yum install -y ssh
fi

#判断服务是否运行
running_num=`systemctl status sshd | grep running |wc -l`
echo -e "running_num=$running_num"
if [ $running_num -gt 0 ]
then
    echo "ssh服务正在运行中---->>>>"
else
    echo "ssh服务重启中---->>>>"
    systemctl restart sshd
fi

#检测ssh key是否已经生成
ssh_key_num=`ls ~/.ssh/ | grep -w "id_rsa" |wc -l`
if [ $ssh_key_num -ge 2 ]
then
    echo "ssh key 已经生成"
else
    ssh-keygen -t rsa -C $1
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
fi
