#1：安装BBR Plus
yum -y install wget
wget --no-check-certificate https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/tcp.sh && chmod +x tcp.sh && ./tcp.sh

#2:测试是否安装完成
wget -qO- --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash

#3：安装SSR
wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocksR.sh
chmod +x shadowsocksR.sh
./shadowsocksR.sh 2>&1 | tee shadowsocksR.log

#逗比版本SS
#wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubiBackup/doubi/master/ssr.sh && chmod +x ssr.sh && bash ssr.sh

#4:卸载SSR
#./shadowsocksR.sh uninstall 
 
#使用命令：
#启动：/etc/init.d/shadowsocks start
#停止：/etc/init.d/shadowsocks stop
#重启：/etc/init.d/shadowsocks restart
#状态：/etc/init.d/shadowsocks status
#配置文件路径：/etc/shadowsocks.json
#日志文件路径：/var/log/shadowsocks.log
#代码安装目录：/usr/local/shadowsocks 