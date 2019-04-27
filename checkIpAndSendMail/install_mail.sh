#! /bin/sh
path_var="/etc/"
file_var="mail"
file_suffix_var=".rc"

src_file=$file_var$file_suffix_var
src_path_file=$path_var$src_file

date_var=$file_var$(date +%Y%m%d)$file_suffix_var
dst_path_file=$path_var$date_var
echo $date_var

if [ ! -f $src_path_file ]
then
    echo "$src_path_file 不存在"
    exit 1
fi
cp -f $src_path_file  $path_var$date_var

keyword='smtp'
var1=`cat $src_path_file | grep -P $keyword |wc -l`
echo "搜索关键词$keyword 数量:$var1"
if [ $var1 -ne 0 ]
then
    echo "邮件配置已经修改过"
    exit 1
fi

echo 'set from="3277364630@qq.com"'           >> $src_path_file  
echo 'set smtp="smtps://smtp.qq.com:465"'      >> $src_path_file 
echo 'set smtp-auth-user="3277364630@qq.com"' >> $src_path_file 
echo 'set smtp-auth-password="Ab123456"'      >> $src_path_file 
echo 'set smtp-auth=login'                      >> $src_path_file   
echo 'set ssl-verify=ignore'                    >> $src_path_file  
echo 'set nss-config-dir=/etc/pki/nssdb'        >> $src_path_file 
