#! /bin/bash

echo "start redis ....."
systemctl start redis


echo "设置开机启动...."
systemctl enable redis
