# 自动部署三台Rockylinux9服务器

(最小化安装，安装基础包，并设定国内源，设静态IP)

1. 安装 EPEL 库，它提供了标准 CentOS/RHEL 库中没有的额外软件包

~~~shell
dnf install -y epel-release
~~~

2. 停止和禁用防火墙

~~~shell
systemctl stop firewalld
systemctl disable firewalld
~~~

3. 通过修改 `/etc/selinux/config` 文件，将 SELinux 设置为禁用

~~~shell
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
~~~

4. 重启系统，查看沙河是否已关

~~~shell
init 6
[root@localhost ~]# getenforce
Disabled
~~~

5. 安装 `cobbler`（一个 Linux 部署服务器）和 `dhcp-server`（DHCP 服务）软件包

~~~shell
dnf -y install cobbler dhcp-server
~~~

6. 使用 MD5 算法生成一个密码的哈希值（用于密码文件中）

~~~shell
openssl passwd -1
$1$L.ZrxRdi$Wh/qWFbEb8kmL2/xcRZ/2/
~~~

7. 使用 Vim 编辑器打开并修改 Cobbler 的设置文件

~~~shell
vim /etc/cobbler/settings.yaml
修改
#设置root密码
default_password_crypted: "$1$L.ZrxRdi$Wh/qWFbEb8kmL2/xcRZ/2/"
# cobbler接管dhcp
manage_dhcp: true
manage_dhcp_v4: true
#cobbler服务器地址
server: 192.168.8.10
#tftp地址
next_server_v4: 192.168.8.10
#cobbler接管tftp
manage_tftpd: true
#当bios首选启动项是pxe时，此项设置为true，可避免重启反复安装系统，否则为false
pxe_just_once: true
~~~

8. 编辑 Cobbler 的 DHCP 配置模板文件

~~~shell
vim /etc/cobbler/dhcp.template
修改
subnet 10.15.200.0 netmask 255.255.255.0 {
     option routers             10.15.200.2;
     option domain-name-servers 8.8.8.8;
     option subnet-mask         255.255.255.0;
     range dynamic-bootp        10.15.200.120 10.15.200.150;
     default-lease-time         21600;
     max-lease-time             43200;
     next-server                $next_server_v4;
~~~

9. 立即启用并启动 `cobblerd` 服务

~~~shell
systemctl enable --now cobblerd
~~~

10. 同步 Cobbler 的配置更改和设置

~~~shell
cobbler sync
~~~

11. 启用并启动 TFTP、Apache HTTPD 和 DHCP 服务

~~~shell
systemctl enable --now tftp httpd dhcpd
~~~

12. 安装 `syslinux`（Linux 启动加载程序）、`dnf-plugins-core`（DNF 插件）和 `pykickstart`（一个用于生成 kickstart 文件的 Python 库）

~~~shell
dnf -y install syslinux dnf-plugins-core pykickstart
~~~

13. 为 Cobbler 创建必要的引导加载器

~~~shell
cobbler mkloaders
~~~

14. 列出 `/var/lib/cobbler/loaders/` 目录中的内容，该目录包含引导加载器文件

~~~shell
ls /var/lib/cobbler/loaders/
~~~

![image-20250306091450118](https://gitee.com/xiaojinliaqi/img/raw/master/202503060914212.png)

15. 将 CD-ROM 挂载到 `/mnt/` 目录

~~~shell
mount /dev/cdrom /mnt/
~~~

16. 从挂载的 CD-ROM 导入 Rocky Linux 9 发行版到 Cobbler，用于自动化部署

~~~shell
cobbler import --name=rocky-9-x86_64 --path=/mnt --arch=x86_64
~~~

17. 列出 Cobbler 中可用的发行版

~~~shell
cobbler distro list
~~~

18. 列出 Cobbler 中可用的配置文件（profile）

~~~shell
cobbler profile list 
~~~

19. 重启 `cobblerd` 服务以应用更改

~~~shell
systemctl restart cobblerd.service
~~~

20. 再次同步 Cobbler 配置

~~~shell
cobbler sync
~~~

21. 分别去三台物理机找到MAC地址

![image-20250306093452742](https://gitee.com/xiaojinliaqi/img/raw/master/202503060934851.png)

~~~shell
00:50:56:23:6A:A7
00:50:56:22:3F:69
00:50:56:31:87:51
~~~

22. 编辑 `rocky9.ks` 文件，定义了安装配置，包括磁盘分区、语言、网络设置、软件包、时区等，启用自动安装

~~~shell
vim /var/lib/cobbler/templates/rocky9.ks
添加
# version=Rocky9
ignoredisk --only-use=nvme0n1
# Partition clearing information
clearpart --all --initlabel
# Use graphical install
text
# Use CDROM installation media
# url --url=http://192.168.8.10/cblr/links/rocky9-x86_64/
url --url=$tree
reboot
# Keyboard layouts
keyboard --vckeymap=cn --xlayouts='cn'
# System language
lang en_US.UTF-8
selinux --disabled
firewall --disabled
# Network information
#network --bootproto=static --device=ens160 --ipv6=auto --activate --hostname=server1 --gateway=192.168.8.2  --ip=192.168.8.100 --netmask=255.255.255.0
# Root password
rootpw --iscrypted $1$L.ZrxRdi$Wh/qWFbEb8kmL2/xcRZ/2/
# Run the Setup Agent on first boot
firstboot --enable
# Do not configure the X Window System
skipx
# System services
services --disabled="chronyd"
# System timezone
timezone Asia/Shanghai --isUtc --nontp
# Disk partitioning information
zerombr
part /boot --fstype="ext4" --ondisk=nvme0n1 --size=1024
part /swap --fstype="swap" --ondisk=nvme0n1 --size=2048
part / --fstype="xfs" --ondisk=nvme0n1 --grow --size=1
%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
%post
#!/bin/sh
# 设置 DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf
dnf install -y epel-release
%end
%post
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/rocky*.rpm  
dnf makecache
dnf update -y
dnf upgrade -y
%end
%packages
@^minimal-environment
vim-enhanced
curl
wget
@Development Tools
@base
%end
%post
#!/bin/sh
#设置允许root用户ssh登录
echo "PermitRootLogin yes" >>/etc/ssh/sshd_config
sysemctl restart sshd
%end
%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
~~~

23. 删除现有的 `rocky-9-x86_64` 配置文件

~~~shell
cobbler profile remove --name rocky-9-x86_64
~~~

24. 使用 `rocky9.ks` Kickstart 文件重新添加该配置文件

~~~shell
cobbler profile add --name rocky-9-x86_64 --distro=rocky-9-x86_64 --autoinstall=rocky9.ks
~~~

25. 重启 Cobbler 服务和同步配置更改

~~~shell
systemctl restart cobblerd.service
cobbler sync 
~~~

26. 查看所有配置文件

~~~shell
cobbler profile list
~~~

27. 使用 Cobbler 将三台服务器（`server1`、`server2`、`server3`）的自动安装配置添加到系统中

~~~shell
sudo cobbler system add --name=server1 --profile=rocky-9-x86_64 --mac-address=00:50:56:23:6a:a7 --static=y --netboot-enabled=y --hostname=server111 --ip-address=10.15.200.121 --netmask=255.255.255.0 --gateway=10.15.200.2
~~~

**`--name=server1`**：添加名为 `server1` 的机器。

**`--profile=rocky-9-x86_64`**：使用之前创建的 `rocky-9-x86_64` 配置文件。

**`--mac-address=00:50:56:23:6a:a7`**：指定该服务器的 MAC 地址。

**`--static=y`**：设置静态 IP。

**`--netboot-enabled=y`**：启用网络启动。

**`--hostname=server111`**：设置该服务器的主机名为 `server111`。

**`--ip-address=10.15.200.121`**：设置该服务器的 IP 地址为 `10.15.200.121`。

**`--netmask=255.255.255.0`**：设置子网掩码。

**`--gateway=10.15.200.2`**：设置网关地址。

28. 为 `server2` 添加相同的配置，但 IP 地址、主机名和 MAC 地址不同

~~~shell
sudo cobbler system add --name=server2     --profile=rocky-9-x86_64     --mac-address=00:50:56:22:3f:69     --static=y     --netboot-enabled=y     --hostname=server222     --ip-address=10.15.200.122     --netmask=255.255.255.0     --gateway=10.15.200.2
~~~

29. 为 `server3` 添加相同的配置，但 IP 地址、主机名和 MAC 地址不同

~~~shell
sudo cobbler system add --name=server3     --profile=rocky-9-x86_64     --mac-address=00:50:56:31:87:51     --static=y     --netboot-enabled=y     --hostname=server333     --ip-address=10.15.200.123     --netmask=255.255.255.0     --gateway=10.15.200.2
~~~





`PXE` 的``应答文件``仅供参考

~~~shell
# Use graphical/text install
text

# baseurl
url --url="http://10.15.200.254/rocky9"

# kdump --disable
%addon com_redhat_kdump --disable
%end

# Root password
rootpw --plaintext 123.com 

# Keyboard layouts
keyboard --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=ens160 --ipv6=auto --activate

%packages
@^minimal-environment
wget
bash-completion
vim
net-tools
lsof
bind-utils
%end

# Run the Setup Agent on first boot
firstboot --enable

# Generated using Blivet version 3.4.0
ignoredisk --only-use=nvme0n1

# Partition clearing information
clearpart --none --initlabel

# Disk partitioning information
part /boot --fstype="xfs" --ondisk=nvme0n1 --size=1024
part swap --fstype="swap" --ondisk=nvme0n1 --size=4096
part pv.155 --fstype="lvmpv" --ondisk=nvme0n1 --size=1 --grow
volgroup rl --pesize=4096 pv.155
logvol / --fstype="xfs" --size=1 --grow --name=root --vgname=rl

# System timezone
timezone Asia/Shanghai --utc

# diabled
firstboot --disable
selinux --disabled
firewall --disabled
reboot

# post_install
%post --interpreter=/usr/bin/bash
mkdir -p /root/.ssh
wget http://10.15.200.254/ssh_key/authorized_keys -O /root/.ssh/authorized_keys
wget http://10.15.200.254/ssh_key/id_rsa -O /root/.ssh/id_rsa
wget http://10.15.200.254/ssh_key/config -O /root/.ssh/config
chmod 600 -R /root/.ssh

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl stop postfix
systemctl disable postfix

rm -fr /etc/yum.repos.d/*.repo
cat>/etc/yum.repos.d/rocky9.repo<<EOF
[AppStream]
name=AppStream
baseurl=http://10.15.200.254/rocky9/AppStream
gpgcheck=0
enabled=1

[BaseOS]
name=BaseOS
baseurl=http://10.15.200.254/rocky9/BaseOS
gpgcheck=0
enabled=1
EOF

%end

~~~

