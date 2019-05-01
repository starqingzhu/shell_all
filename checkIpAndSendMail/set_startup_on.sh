#! /bin/sh

#设置脚本开机启动

srcPath=`pwd`"/"
srcName="check_ip_change.sh"

dstPath="/etc/rc.d/init.d/"
dstName="check_ip_change.sh"
#复制脚本到目的目录下
echo "cp $srcPath$srcName  $dstPath$dstName"
cp $srcPath$srcName  $dstPath$dstName

#修改可执行权限
echo "chmod +x $dstPath$dstName"
chmod +x $dstPath$dstName

#文件/etc/rc.d/rc.local标记为可执行
startFileName="/etc/rc.d/rc.local"
echo "chmod +x $startFileName"
chmod +x $startFileName

#备份修改的文件
date_var="_"`date +%Y%m%d`
echo "cp $startFileName $startFileName$date_var"
cp -f $startFileName $startFileName$date_var

#查看是否添加过
keyword=$dstPath$dstName

echo "grep  $keyword $startFileName  | wc -l"
count=`grep  $keyword $startFileName  | wc -l`

echo "count="$count
if [ $count -lt 1 ]
then
    echo "$dstPath$dstName -->>> $startFileName"
    echo "$dstPath$dstName" >> $startFileName
fi
