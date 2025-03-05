# 安装部署Ubuntu22.04服务器

##  1.准备Ubuntu镜像

镜像名称：ubuntu-22.04-live-server-amd64.iso
https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso

## 2.VMware

![image-20250304155917721](https://gitee.com/xiaojinliaqi/img/raw/master/202503041559755.png)

![image-20250304160057045](https://gitee.com/xiaojinliaqi/img/raw/master/202503041600088.png)

![image-20250304160459252](https://gitee.com/xiaojinliaqi/img/raw/master/202503041604319.png)

选择语言，回车键下一步

![image-20250304160624059](https://gitee.com/xiaojinliaqi/img/raw/master/202503041606107.png)

![image-20250304161910911](https://gitee.com/xiaojinliaqi/img/raw/master/202503041619951.png)

![image-20250304161336837](https://gitee.com/xiaojinliaqi/img/raw/master/202503041613887.png)

![image-20250304162006417](https://gitee.com/xiaojinliaqi/img/raw/master/202503041620460.png)

![image-20250304162026138](https://gitee.com/xiaojinliaqi/img/raw/master/202503041620188.png)

![image-20250304162046575](https://gitee.com/xiaojinliaqi/img/raw/master/202503041620627.png)

![image-20250304162637191](https://gitee.com/xiaojinliaqi/img/raw/master/202503041626232.png)

![image-20250304162709991](https://gitee.com/xiaojinliaqi/img/raw/master/202503041627040.png)

![image-20250304162823980](https://gitee.com/xiaojinliaqi/img/raw/master/202503041628039.png)

![image-20250304162923365](https://gitee.com/xiaojinliaqi/img/raw/master/202503041629414.png)

![image-20250304163034703](https://gitee.com/xiaojinliaqi/img/raw/master/202503041630744.png)

![image-20250304163048805](https://gitee.com/xiaojinliaqi/img/raw/master/202503041630838.png)

![image-20250304163108916](https://gitee.com/xiaojinliaqi/img/raw/master/202503041631956.png)



## 3.更新国内源



~~~shell
user1@user1:~$ sudo -i
root@user1:~# sudo cat > /etc/apt/sources.list EOF
deb https:mirrors.aliyun.com/ubuntu/ jammy main restricted universe
multiverse
deb-src https:mirrors.aliyun.com/ubuntu/ jammy main restricted universe
multiverse
deb https:mirrors.aliyun.com/ubuntu/ jammy-security main restricted
universe multiverse
deb-src https:mirrors.aliyun.com/ubuntu/ jammy-security main restricted
universe multiverse
deb https:mirrors.aliyun.com/ubuntu/ jammy-updates main restricted
universe multiverse
deb-src https:mirrors.aliyun.com/ubuntu/ jammy-updates main restricted
universe multiverse
deb https:mirrors.aliyun.com/ubuntu/ jammy-backports main restricted
universe multiverse
deb-src https:mirrors.aliyun.com/ubuntu/ jammy-backports main restricted
universe multiverse
EOF
# apt update
# apt upgrade -y
~~~



## 4.安装常用工具

~~~shell
apt install curl wget net-tools
apt install iputils-ping sysstat dstat zip unzip gzip vim
apt install vim bash-completion
apt install build-essential
apt autoremove
apt clean
~~~



## 5.设置静态IP

~~~shell
vim /etc/netplan/00-installer-config.yaml
network:
  ethernets:
    ens33:
      dhcp4: false
      addresses: [10.15.200.128/24]
      routes:
        - to: default
          via: 10.15.200.2
      nameservers:
        addresses: [223.5.5.5,223.6.6.6]
  version: 2


~~~

地址生效

~~~shell
netplan apply 
~~~

## 6.设置ROOT远程ssh连接

~~~shell
#先给root设置密码
passwd 
~~~

~~~shell
vim /etc/ssh/sshd_config

33行 PermitRootLogin yes
58行取消注释 PasswordAuthentication yes
102行取消注释 UseDNS no

systemctl restart sshd
~~~



