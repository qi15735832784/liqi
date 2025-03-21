# ansible角色部署基于lnmp环境搭建zabbix

## 实验环境

两台rocky9的主机【IP分别为：`控制端10.15.200.100`，`被控制端10.15.200.134`】

## 实验步骤

### 控制端和被控制端免密

~~~shell
#控制端
ssh-keygen
ssh-copy-id root@10.15.200.134

#被控制端
ssh-keygen
ssh-copy-id root@10.15.200.100
~~~

![image-20250318175009320](https://gitee.com/xiaojinliaqi/img/raw/master/202503181750454.png)

### 控制端安装ansible

~~~shell
dnf -y install epel-release
dnf -y install ansible
~~~

