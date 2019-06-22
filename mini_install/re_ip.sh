#! /bin/sh

#新的机器执行需要修改的字段 NAME  DEVICE IPADDR GATEWAY DNS1 DNS2
#查看当前机器的语言字符集
cat /etc/locale.conf

#查看当前ip
ip addr

#修改/etc/sysconfig/network-scripts/ifcfg-eth0
echo 'TYPE="Ethernet"' > /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'PROXY_METHOD="none"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'BROWSER_ONLY="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'BOOTPROTO="static"' >> /etc/sysconfig/network-scripts/ifcfg-eth0 #dhcp为动态  static为静态 ip
echo 'DEFROUTE="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'PEERDNS="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'PEERROUTES="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPV4_FAILURE_FATAL="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPV6INIT="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPV6_AUTOCONF="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPV6_DEFROUTE="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPV6_PEERDNS="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPV6_PEERROUTES="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPV6_FAILURE_FATAL="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPV6_ADDR_GEN_MODE="stable-privacy"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'NAME="eth0"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo '#UUID="4bcf16f5-ae8b-4a38-898d-da32f34c3ca0"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'DEVICE="eth0"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'ONBOOT="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0 #开机启用本配置
echo 'NM_CONTROLLED=no' >> /etc/sysconfig/network-scripts/ifcfg-eth0

echo 'IPADDR=192.168.2.121' >> /etc/sysconfig/network-scripts/ifcfg-eth0   #静态ip
echo 'GATEWAY=192.168.2.1' >> /etc/sysconfig/network-scripts/ifcfg-eth0    #默认网关
echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-eth0  #子网掩码
echo 'DNS1=192.168.2.1' >> /etc/sysconfig/network-scripts/ifcfg-eth0      #首选dns服务器

#重启
systemctl restart network
