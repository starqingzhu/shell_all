#! /usr/sh

param_min=1
param_max=1
echo "输入参数:"$*
if [ $# -lt $param_min  ] || [ $# -gt $param_max  ]
then
    echo "参数个数异常:[$param_min~$param_max]"
    exit 1
fi

ps -ef | grep $1 | grep -v 'grep' | grep -v 'tail' |awk '{print $2}' | xargs kill -9
