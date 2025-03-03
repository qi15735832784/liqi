# 部署Rocky-linux9(最小化安装)

## 第一步：虚拟机上配置

![image-20250303145501929](https://gitee.com/xiaojinliaqi/img/raw/master/202503031455006.png)

选择

![image-20250303145617211](https://gitee.com/xiaojinliaqi/img/raw/master/202503031456271.png)

![image-20250303145652294](https://gitee.com/xiaojinliaqi/img/raw/master/202503031456350.png)

![image-20250303145731736](https://gitee.com/xiaojinliaqi/img/raw/master/202503031457800.png)

![image-20250303145939337](https://gitee.com/xiaojinliaqi/img/raw/master/202503031459410.png)

![image-20250303150022384](https://gitee.com/xiaojinliaqi/img/raw/master/202503031500447.png)

![image-20250303150244322](https://gitee.com/xiaojinliaqi/img/raw/master/202503031502377.png)

## 第二步：开启虚拟机（装机）

![](https://gitee.com/xiaojinliaqi/img/raw/master/202503031504115.png)

![image-20250303150932810](https://gitee.com/xiaojinliaqi/img/raw/master/202503031509897.png)

![image-20250303151310954](https://gitee.com/xiaojinliaqi/img/raw/master/202503031513039.png)

选择最小安装的界面

![image-20250303151421690](https://gitee.com/xiaojinliaqi/img/raw/master/202503031514786.png)

设置密码的界面

![image-20250303151648335](https://gitee.com/xiaojinliaqi/img/raw/master/202503031516399.png)

最后等待装机完成

## 第三步：基础的配置

要是之前装机的时候没有点击允许远程连接如下操作

~~~shell
vi /etc/ssh/sshd_config
修改
#PermitRootLogin prohibit-password
PermitRootLogin yes
#PasswordAuthentication yes
PasswordAuthentication yes
UseDNS no

最后重启 systemctl restart sshd
~~~



配置静态IP

第一种方法

~~~shell
vi /etc/NetworkManager/system-connections/ens160.nmconnection 
#添加：
[ipv4]
address=10.15.200.100/24,10.15.200.2
dns=223.5.5.5;223.6.6.6
method=manual

重启 init 6
~~~

第二种方法（命令）

~~~shell
#为网络接口 ens160 配置一个静态的 IPv4 地址 
nmcli connection modify ens160 ipv4.addresses 10.15.200.100/24
#将 ens160 接口的 IPv4 地址分配方式设置为手动配置
nmcli connection modify ens160 ipv4.method manual 
#为 ens160 接口设置网关
nmcli connection modify ens160 ipv4.gateway 10.15.200.2
#为 ens160 接口配置 DNS 服务器
nmcli connection modify ens160 ipv4.dns 223.5.5.5,223.6.6.6
#激活修改后的 ens160 网络连接
nmcli connection up ens160 
~~~



更新国内源

~~~shell
https://developer.aliyun.com/mirror/rockylinux?spm=a2c6h.13651102.0.0.6bd71b11AQWOKP
~~~

更新版本为最新版

~~~shell
dnf update -y
dnf upgrade -y
dnf -y groupinstall "Development Tools"
dnf -y groupinstall "base"
dnf -y install lrzsz
~~~

