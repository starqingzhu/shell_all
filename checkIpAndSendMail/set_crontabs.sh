#! /bin/sh

# 安装crontabs服务并设置开机自启动
yum install -y crontabs
systemctl enable crond
systemctl start crond

# 设置任务
mission_var="*/10 * * * * root /etc/rc.d/init.d/check_ip_change.sh"
keyword="check_ip_change"
dst_file_name="/etc/crontab"
count=`grep $keyword $dst_file_name | wc -l`
echo -e "grep $keyword $dst_file_name | wc -l\n  count=$count"

if [ $count -lt 1 ]
then
	echo $mission_var >> $dst_file_name
	echo "$mission_var -->> $dst_file_name"
fi



# 保存生效
crontab /etc/crontab

# 查看任务
crontab -l


