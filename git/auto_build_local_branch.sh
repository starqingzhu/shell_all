#! /usr/sh

param_min=2
param_max=2
match_count="1"

create="create"
destroy="destroy"

#echo "命令行参数:"$*

if [ $# -lt $param_min  ] || [ $# -gt $param_max  ]
then
        echo "参数个数为:"$#"  ,范围:[$param_min~$param_max]"
        echo "用法:sh shell.sh [create/destroy] branchname"
     
        exit 1
fi


if [ $create = $1 ]
then
	git checkout master
	git pull
	git checkout -b $2
	git push origin $2
fi
#
if [ $destroy = $1 ]
then
	git checkout master
	git branch -r -d origin/$2
	git push origin :$2
	git branch -d $2
fi
