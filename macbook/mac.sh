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

gbpath="/Users/admin/proj/shell_all"
alias gbcrt="sh $gbpath/git/auto_build_local_branch.sh create"
alias gbmg="sh $gbpath/git/auto_build_local_branch.sh merge"
alias gbdst="sh $gbpath/git/auto_build_local_branch.sh destroy"


#git submodule
alias gsu="git submodule update"


#go test
alias gotest="go test -test.run"
alias govtest="go test -v -test.run"
alias gobench="go test -v -run none -bench"

#shell
alias ll="ls -l"
alias la="ls -a"
alias lla="ls -al"

#项目
#funplus
#杀项目进程
killPath="sh /Users/admin/proj/shell_all/fpserver/kill.sh"
alias kglobal=$killPath" globalserver"
alias kgame=$killPath" gameserver"
alias kmatch=$killPath" matchserver"
alias kroom=$killPath" roomserver"
alias kplat=$killPath" platformserver"
#编译proto
alias mcgame="cd /Users/admin/proj/funplus/fppokerserver/gameserver && make conf && cd -"
alias mcmatch="cd /Users/admin/proj/funplus/fppokerserver/matchserver && make conf && cd -"
alias mcroom="cd /Users/admin/proj/funplus/fppokerserver/roomserver && make conf && cd -"
alias mcplat="cd /Users/admin/proj/funplus/fppokerserver/platformserver && make conf && cd -"
alias mcall="mcgame && mcmatch && mcroom && mcplat"
#杀掉进程
alias kall="sh /Users/admin/proj/shell_all/fpserver/kall.sh"
# 编译 && 部署
alias mdglobal="cd /Users/admin/proj/funplus/fppokerserver/globalserver && make deploy && cd -"
alias mdgame="cd /Users/admin/proj/funplus/fppokerserver/gameserver && make deploy  && cd -"
alias mdmatch="cd /Users/admin/proj/funplus/fppokerserver/matchserver && make deploy && cd -"
alias mdroom="cd /Users/admin/proj/funplus/fppokerserver/roomserver && make deploy  && cd -"
alias mdplat="cd /Users/admin/proj/funplus/fppokerserver/platformserver && make deploy  && cd -"
alias mdall="mdglobal && mdgame && mdmatch && mdroom && mdplat"
# 编译 && 部署  linux版本
alias mdlglobal="cd /Users/admin/proj/funplus/fppokerserver/globalserver && make deploy-linux && cd -"
alias mdlgame="cd /Users/admin/proj/funplus/fppokerserver/gameserver && make deploy-linux && cd -"
alias mdlmatch="cd /Users/admin/proj/funplus/fppokerserver/matchserver && make deploy-linux && cd -"
alias mdlroom="cd /Users/admin/proj/funplus/fppokerserver/roomserver && make deploy-linux  && cd -"
alias mdlroom="cd /Users/admin/proj/funplus/fppokerserver/platformserver && make deploy-linux  && cd -"
alias mdlall="mdlgame && mdlmatch && mdlroom && mdlplat"
# 编译 && 部署 && 启动 各个服务
alias mrglobal="cd /Users/admin/proj/funplus/fppokerserver/globalserver &&  make run && cd -"
alias mrgame="cd /Users/admin/proj/funplus/fppokerserver/gameserver && make run && cd -"
alias mrmatch="cd /Users/admin/proj/funplus/fppokerserver/matchserver && make run && cd -"
alias mrroom="cd /Users/admin/proj/funplus/fppokerserver/roomserver && make run && cd -"
alias mrplat="cd /Users/admin/proj/funplus/fppokerserver/platformserver && make run && cd -"
alias mrall="mrglobal && mrgame && mrmatch && mrroom && mrplat"
#重启
alias msall="msgame && msmatch && msroom && msplat"
alias msgame="cd /Users/admin/proj/funplus/fppokerserver/local_deployment/gameserver && ./control.sh restart gameserver && cd -"
alias msglobal="cd /Users/admin/proj/funplus/fppokerserver/local_deployment/globalserver && ./control.sh restart globalserver && cd -"
alias msmatch="cd /Users/admin/proj/funplus/fppokerserver/local_deployment/matchserver && ./control.sh restart matchserver && cd -"
alias msroom="cd /Users/admin/proj/funplus/fppokerserver/local_deployment/roomserver && ./control.sh restart roomserver && cd -"
alias msplat="cd /Users/admin/proj/funplus/fppokerserver/local_deployment/platserver && ./control.sh restart platformserver && cd -"

#压测环境
alias global1="ssh centos@3.221.127.117"
alias global2="ssh centos@34.205.45.59"
alias game1="ssh centos@18.234.199.191"
alias game2="ssh centos@3.230.119.191"
alias match1="ssh centos@3.235.153.74"
alias match2="ssh centos@3.238.70.118"
alias room1="ssh centos@3.237.70.29"
alias room2="ssh centos@18.214.37.151"
alias plat1="ssh centos@3.95.230.15"
alias plat2="ssh centos@35.170.185.78"
alias admin="ssh centos@34.201.72.80"

#线下测试机
alias tb="ssh -p 2222 bin.sun@10.7.73.2"

#brew
alias serverlist="brew services list"
alias serverStart="brew services start"
alias serverReStart="brew services restart"
alias serverStop="brew services stop"

#etcd
alias etcdStart="brew services start etcd"
alias etcdStop="brew services stop etcd"

#etcd ctl
alias etcdok="etcdctl endpoint health"


#path
PATH="/Applications/CMake.app/Contents/bin":"$PATH"

#work
alias swork="cd ~/proj/funplus/fppokerserver/"
