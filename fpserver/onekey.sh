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
#conf
confComm="&& make conf"
gamenameconf="cd $work_dir$gamename "$confComm
matchnameconf="cd $work_dir$matchname "$confComm
roomnameconf="cd $work_dir$roomname"$confComm
alias mcgame=$gamenameconf
alias mcmatch=$matchnameconf
alias mcroom=$roomnameconf
alias mcall="mcgame && mcmatch && mcroom"

#deploy
deployComm="&& make deploy"
gamenamedp="cd "$work_dir$gamename" "$deployComm
matchnamedp="cd "$work_dir$matchname" "$deployComm
roomnamedp="cd "$work_dir$roomname" "$deployComm
alias mdgame=$gamenamedp
alias mdmatch=$matchnamedp
alias mdroom=$roomnamedp
alias mdall="mdgame && mdmatch && mdroom"

#run
runComm="&& make run"
gamenamemr="cd "$work_dir$gamename" "$runComm
matchnamemr="cd "$work_dir$matchname" "$runComm
roomnamemr="cd "$work_dir$roomname" "$runComm
alias mrgame=$gamenamemr
alias mrmatch=$matchnamemr
alias mrroom=$roomnamemr
alias mrall="mrgame && mrmatch && mrroom"

alias swork="cd $work_dir"
confPath=$work_dir"deployment/assets/conf/"
alias sconf="cd confPath"
echo $confPath

#kill
kglobalpath="sh "$shell_dir"kill.sh globalserver"
kgamepath="sh "$shell_dir"kill.sh gameserver"
kmatchpath="sh "$shell_dir"kill.sh matchserver"
kroompath="sh "$shell_dir"kill.sh roomserver"
kallpath="sh "$shell_dir"killall.sh"

alias kglobal=$kglobalpath
alias kgame=$kgamepath
alias kmatch=$kmatchpath
alias kroom=$kroompath
alias kall=$kallpath