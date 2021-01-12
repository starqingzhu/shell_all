#! /usr/sh

gamename="gameserver"
matchname="matchserver"
roomname="roomserver"

#检测参数数量
param_min=2
param_max=2

if [ $# -lt $param_min  ] || [ $# -gt $param_max  ]
then
    echo "参数个数异常:[$param_min~$param_max]"
    exit 1
fi

if [ ! -f "$2" ]; then
  echo "$1 not exist"
fi

srcFile=$2
srcFileZip=$2".zip"
echo "$1 $2 exist"
time=$(date "+%Y%m%d_%H%M%S")

zip $srcFileZip $srcFile

function CopyGame(){
   echo "copy game"
   scp $srcFileZip centos@3.238.35.113:/home/centos/server/gameserver/
   ssh centos@3.238.35.113 "cd /home/centos/server/gameserver/ && unzip gameserver.zip && cd - && pwd"
   scp $srcFileZip centos@18.234.199.247:/home/centos/server/gameserver/
   ssh centos@18.234.199.247 "cd /home/centos/server/gameserver/ && unzip gameserver.zip  && cd - && pwd"
}
function CopyMatch(){
   echo "copy match"
   scp  $srcFileZip centos@3.235.85.37:/home/centos/server/matchserver/
   ssh centos@3.235.85.37 "cd /home/centos/server/matchserver/ && unzip matchserver.zip && cd - && pwd"
   scp  $srcFileZip centos@3.208.92.94:/home/centos/server/matchserver/
   ssh centos@3.208.92.94 "cd /home/centos/server/matchserver/ && unzip matchserver.zip && cd - && pwd"
}
function CopyRoom(){
   echo "copy room"
   scp  $srcFileZip centos@3.237.174.152:/home/centos/server/roomserver/
   ssh centos@3.237.174.152 "cd /home/centos/server/roomserver/ && unzip roomserver.zip && cd - && pwd"
   scp  $srcFileZip centos@3.210.198.223:/home/centos/server/roomserver/
   ssh centos@3.210.198.223 "cd /home/centos/server/roomserver/ && unzip roomserver.zip && cd - && pwd"
   scp  $srcFileZip centos@34.201.242.27:/home/centos/server/roomserver/
   ssh centos@34.201.242.27 "cd /home/centos/server/roomserver/ && unzip roomserver.zip && cd - && pwd"
   scp  $srcFileZip centos@3.83.53.10:/home/centos/server/roomserver/
   ssh centos@3.83.53.10 "cd /home/centos/server/roomserver/ && unzip roomserver.zip && cd - && pwd"
}
if [ $1 == $gamename ]
then
    #执行函数
    CopyGame
elif [ $1 == $matchname ]
then
    #执行函数
    CopyMatch
elif [ $1 == $roomname ]
then
    #执行函数
    CopyRoom
fi
