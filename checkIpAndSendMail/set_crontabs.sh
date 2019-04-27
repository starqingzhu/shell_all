#! /bin/sh

# 安装crontabs服务并设置开机自启动

echo -e "\n\n----------定时任务脚本开始执行----------"
crontabs_var=`yum list installed | grep crontabs |wc -l`
if [ $crontabs_var -lt 1 ]
then
    yum install -y crontabs
else
    echo "crontabs 已安装"
fi
systemctl enable crond
systemctl start crond

# 设置任务
mission_var="*/10 * * * * root /etc/rc.d/init.d/check_ip_change.sh"
keyword="check_ip_change"
dst_file_name="/etc/crontab"
count=`grep $keyword $dst_file_name | wc -l`
echo -e "grep $keyword $dst_file_name | wc -l\n----->count=$count"

if [ $count -lt 1 ]
then
	echo "$mission_var -->> $dst_file_name"
	echo "$mission_var" >> $dst_file_name
fi


echo -e "--------------------------------------------\n\n"

# 保存生效
crontab /etc/crontab

# 查看任务
crontab -l


echo -e "--------------------------------------------\n\n"
