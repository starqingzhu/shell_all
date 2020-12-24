#!/bin/bash
ps -ef | grep -E "gameserver|matchserver|roomserver|globalserver" | grep -v grep | grep -v tail | awk '{print $2}' | xargs kill
sleep 1
ret=`ps -ef | grep -E "gameserver|matchserver|roomserver|globalserver" | grep -v grep | grep -v tail`
if [ "${ret}" = "" ];then
    echo "kill complate."
else
    echo "some service not killed.\n\t${ret}"
fi
