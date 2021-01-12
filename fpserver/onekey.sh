#! /usr/sh

work_dir="/Users/supersun/funplus/proj/texas/fppokerserver/"
shell_dir="/Users/supersun/proj/shell_all/fpserver/"

echo $work_dir

#git相关
alias ga="git add"
alias gb="git branch"
alias gc="git checkout"
alias gd="git diff"
alias gs="git status"
alias gm="git commit"
alias gph="git push"
alias gpl="git pull"
alias gmg="git merge"
alias gfmt="gofmt -w"
alias gv="git remote -v"
alias gfr="git fetch --all && git reset --hard origin/master && git pull"

gbcrtname="sh "$shell_dir" create"
gbmgname="sh "$shell_dir" merge"
alias gbcrt=$gbcrtname
alias gbmg=$gbmgname



#go test
alias gotest="go test -test.run"
alias govtest="go test -v -test.run"
alias gobench="go test -v -run none -bench"


#进程处理相关
alias fkill="kill -9"


#etcd 开机自动启动
alias setcdstart="etcd &"
#alias setcdstop="ps -ef | grep etcd | grep -v grep | awk '{print $2}' | xargs sudo kill -9"

#etcd帮助页面
alias etcdhp="cd /Users/supersun/proj/etcd/etcd-browser/ && node server.js"
alias etcdok="etcdctl endpoint health" #检测etcd 是否运行
alias etcdst="etcdctl endpoint status" #检测etcd 状态
alias etcdmem="etcdctl member list" #列出集群成员

# etcd查看管理节点
alias etcdkp="/Users/supersun/funplus/kit/etcdkeeper/etcdkeeper"

#rabbitmq
alias srbstart="sudo rabbitmq-server"
alias srbstop="ps -ef | grep rabbitmq-server | grep -v grep | awk '{print $2}'| xargs sudo kill -9"
alias rbprint="ps -ef | grep -v grep | grep  rabbitmq-server"

#redis
alias rdstart="redis-server &"
alias rdstop="redis-cli SHUTDOWN"

#mysql
alias mystart="sudo mysql.server start"
alias mystop="sudo mysql.server stop"

#funplus poker服务
strfpsastart="source "$shell_dir"start.sh"
echo $strfpsastart
strfpsastop="source "$shell_dir"stop.sh"
echo $strfpsastop

alias fpsastart=$strfpsastart
alias fpsastop=$strfpsastop


gamename="gameserver"
matchname="matchserver"
roomname="roomserver"
globalname="globalserver"
#conf
confComm="&& make conf"
gamenameconf="cd $work_dir$gamename "$confComm
matchnameconf="cd $work_dir$matchname "$confComm
roomnameconf="cd $work_dir$roomname"$confComm
globalnameconf="cd $work_dir$globalname"$confComm
alias mcgame=$gamenameconf
alias mcmatch=$matchnameconf
alias mcroom=$roomnameconf
alias mcglobal=$globalnameconf
alias mcall="mcgame && mcmatch && mcroom && mcglobal"

#deploy
deployComm="&& make deploy && make run && cd -"
gamenamedp="cd "$work_dir$gamename" "$deployComm
matchnamedp="cd "$work_dir$matchname" "$deployComm
roomnamedp="cd "$work_dir$roomname" "$deployComm
globalnamedp="cd "$work_dir$globalname" "$deployComm
alias mrgame=$gamenamedp
alias mrmatch=$matchnamedp
alias mrroom=$roomnamedp
alias mrglobal=$globalnamedp
alias mrall="mrgame && mrmatch && mrroom && mrglobal"

#run
localname="local_deployment/"
runComm="&& ./control.sh restart "
gamenamemr="cd "$work_dir$localname$gamename" "$runComm
matchnamemr="cd "$work_dir$localname$matchname" "$runComm
roomnamemr="cd "$work_dir$localname$roomname" "$runComm
globalnamemr="cd "$work_dir$localname$globalname" "$runComm
alias msgame=$gamenamemr
alias msmatch=$matchnamemr
alias msroom=$roomnamemr
alias msglobal=$globalnamemr
alias msall="mrgame && mrmatch && mrroom && msglobal"

alias swork="cd $work_dir"
confPath=$work_dir"deployment/assets/conf/"
alias sconf="cd confPath"
echo $confPath

#kill
kallname="sh $shell_dir""/kall.sh"
alias kall=$kallname

#prometheus
prometheus_work_dir="/root/proj/prometheus_dir/prometheus-2.24.0-rc.0.linux-amd64"
promStart="cd $prometheus_work_dir && ./prometheus  --config.file=prometheus.yml &  && cd -"
