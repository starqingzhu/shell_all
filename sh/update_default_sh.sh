#! /usr/sh

param_min=1
param_max=1
match_count="1"

echo "命令行参数:"$*

if [ $# -lt $param_min  ] || [ $# -gt $param_max  ]
then
	echo "参数个数为:"$#"  ,范围:[$param_min~$param_max]"
	echo "shell类型列表:"
	cat /etc/shells | grep bin | cut -d"/" -f 3
	exit 1
fi

count=`cat /etc/shells | grep bin | cut -d"/" -f 3 | grep -w $* |wc -l`
if [ $count -ne $match_count ]
then
	echo "参数输入错误，shell类型列表如下:"
	cat /etc/shells | grep bin | cut -d"/" -f 3
	exit 1
fi


bash_param="/bin/"$1

chsh -s $bash_param