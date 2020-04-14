#! /usr/sh

param_min=2
param_max=3
match_count="1"

create="create"
destroy="destroy"
merge="merge"

#echo "命令行参数:"$*

if [ $# -lt $param_min  ] || [ $# -gt $param_max  ]
then
        echo "参数个数为:"$#"  ,范围:[$param_min~$param_max]"
        echo "用法:sh shell.sh [create/destroy] branchname"
     
        exit 1
fi


if [ $create = $1 ]
then
	git checkout $2
	git pull
	git checkout -b $3
	git push origin $3
	git push --set-upstream origin $3
fi

if [ $destroy = $1 ]
then
	git checkout master
	git branch -D $2
	git push origin --delete $2
fi

if [ $merge = $1 ]
then
	echo "切换分支到$2"
	git checkout $2
	git pull
	echo "切换分支到$3"
	git checkout $3
	git pull
	echo "分支$2合并到$3"
	git merge $2
fi
