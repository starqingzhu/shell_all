EADME.md
#1.确定mailx插件是否安装
yum -y install mailx

#2.执行脚本，修改配置文件
sh install_mail.sh

#3.手动测试是否修改成功
echo "你好呀"  | mail -v -s "测试邮件1"  3277364630@qq.com

#4.设置开机启动 通过日志查看定时任务是否ok
sh set_startup_on.sh
systemctl status crond
