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

# 自动化部署系统

## cobbler 批量安装Rockylinux9

安装软件（yum源必须有epel源）

~~~shell
dnf install -y epel-release
~~~

关闭防火墙和沙河然后重启

~~~shell
systemctl stop firewalld && systemctl disable firewalld
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
reboot
~~~

部署Cobbler

安装软件

~~~shell
dnf -y install cobbler dhcp-server
~~~

配置cobbler。生成密文密码

~~~shell
openssl passwd -1
$1$RcOmy101$lw0TpqbMlxzijQjyXuAqj0     #每次生成的不一样
~~~

修改Cobbler主配置文件

~~~shell
vi /etc/cobbler/settings.yaml
#设置root密码
default_password_crypted: "$1$j9.vkIK0$VSWMRW9sXlEbC.PZNgjwG/"
# cobbler接管dhcp
manage_dhcp: true
manage_dhcp_v4: true
#cobbler服务器地址
server: 10.15.200.100
#tftp地址
next_server_v4: 10.15.200.100
#cobbler接管tftp
manage_tftpd: true
#当bios首选启动项是pxe时，此项设置为true，可避免重启反复安装系统，否则为false
pxe_just_once: true
~~~

修改dhcp模版文件

~~~shell
# vi /etc/cobbler/dhcp.template
subnet 10.15.200.0 netmask 255.255.255.0 {
     option routers             10.15.200.2;
     option domain-name-servers 8.8.8.8;
     option subnet-mask         255.255.255.0;
     range dynamic-bootp        10.15.200.110 10.15.200.200;
     default-lease-time         21600;
     max-lease-time             43200;
     next-server                $next_server_v4;
~~~

 启动cobbler，同步配置

~~~shell
# systemctl enable --now cobblerd
# cobbler sync
~~~

启动dhcp、tftp、http服务

~~~shell
# systemctl enable --now tftp httpd dhcpd
~~~

cobbler配置检查

~~~shell
# cobbler check
The following are potential configuration items that you may want to fix:

1: For PXE to be functional, the 'next_server_v6' field in /etc/cobbler/settings.yaml must be set to something other than ::1, and should match the IP of the boot server on the PXE network.
2: some network boot-loaders are missing from /var/lib/cobbler/loaders. If you only want to handle x86/x86_64 netbooting, you may ensure that you have installed a *recent* version of the syslinux package installed and can ignore this message entirely. Files in this directory, should you want to support all architectures, should include pxelinux.0, andmenu.c32.
3: reposync is not installed, install yum-utils or dnf-plugins-core
4: yumdownloader is not installed, install yum-utils or dnf-plugins-core
5: debmirror package is not installed, it will be required to manage debian deployments and repositories
6: ksvalidator was not found, install pykickstart
7: fencing tools were not found, and are required to use the (optional) power management features. install cman or fence-agents to use them

Restart cobblerd and then run 'cobbler sync' to apply changes.

~~~

排错思路

**1.问题： `next_server_v6` 字段设置为 `::1`，这是 IPv6 的回环地址，意味着它指向本地机器。这会导致 PXE 启动失败，因为其他机器无法通过这个地址找到 PXE 服务器。****

**解决： 打开 `/etc/cobbler/settings.yaml` 文件，找到 `next_server_v6` 配置项，将其设置为你的 PXE 服务器的 IPv6 地址或 IPv4 地址（例如：`192.168.1.1`）。然后重新启动 `cobblerd` 服务并同步。**

**2.问题： `/var/lib/cobbler/loaders` 目录中缺少一些网络引导加载程序文件，可能是因为你没有安装正确版本的 `syslinux` 或者没有相关的文件。**

**解决： 安装 `syslinux` 包，它包含 `pxelinux.0` 和 `menu.c32` 等文件**

**3.问题： `reposync` 用于同步仓库数据，但系统没有安装它。它通常由 `yum-utils` 或 `dnf-plugins-core` 提供。**

**解决： 安装 `yum-utils` 或 `dnf-plugins-core`**

**4.问题： `yumdownloader` 用于下载软件包，但系统没有安装它。它也属于 `yum-utils` 或 `dnf-plugins-core` 包的一部分。**

**解决： 安装 `yum-utils` 或 `dnf-plugins-core`**

**5.问题： 如果你需要处理 Debian 系统的部署和仓库管理，`debmirror` 工具是必需的，但它没有安装。**

**解决： 安装 `debmirror` 包**

**6.问题： `ksvalidator` 是用于验证 Kickstart 配置文件的工具，系统中没有安装它。**

**解决： 安装 `pykickstart` 包**

**7.问题： 如果你打算使用电源管理（比如关闭或重启远程服务器），你需要安装 `fencing` 工具。**

**解决： 安装 `cman` 或 `fence-agents**`****



根据check结果提示安装相关包，其它错误可忽略

~~~shell
# dnf -y install syslinux dnf-plugins-core pykickstart
~~~

生成引导加载程序 cobbler mkloaders ，此命令适用cobblerV3.3.1及之后的版本

~~~shell
# cobbler mkloaders
~~~

查看

~~~shell
# ls /var/lib/cobbler/loaders/
grub         libcom32.c32  linux.c32  menu.c32
ldlinux.c32  libutil.c32   memdisk    pxelinux.0
~~~

导入系统镜像资源

挂载光盘镜像

~~~shell
# mount /dev/cdrom /mnt
~~~

导入系统镜像资源，并查看

~~~shell
# cobbler import --name=rocky-9-x86_64 --path=/mnt/ --arch=x86_64
~~~

自定义的Rocky9.1的应答文件

~~~shell
# vim /var/lib/cobbler/templates/rocky9.ks
~~~

~~~shell
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

network  --bootproto=dhcp --device=ens33 --ipv6=auto --activate

# Root password

rootpw --iscrypted $1$RcOmy101$lw0TpqbMlxzijQjyXuAqj0

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

%packages

@^minimal-environment

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

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

更新启动菜单

~~~shell
# cobbler profile remove --name rocky-9-x86_64
# cobbler profile add --name rocky-9-x86_64 --distro=rocky-9-x86_64 --autoinstall=rocky9.ks
~~~

重启cobbler，同步配置

~~~shell
# systemctl restart cobblerd
# cobbler sync
# cobbler profile list
   rocky-9-x86_64
~~~

最后使用虚拟机测试机

## 使用 `Cobbler` 配置 PXE 部署环境的步骤

~~~shell
# dnf install -y epel-release
作用： 安装 EPEL（Extra Packages for Enterprise Linux）仓库，提供额外的软件包支持。
解释： 这为系统添加了更多的非标准包来源，许多软件包依赖于这个仓库。
# systemctl stop firewalld
作用： 停止 firewalld 防火墙服务。
解释： PXE 启动过程中可能会受到防火墙的阻碍，因此关闭防火墙以确保没有网络访问问题。
# systemctl disable firewalld
作用： 禁用 firewalld 防火墙服务，以确保系统启动时不再启用防火墙。
解释： 这使得防火墙不会在系统重启后自动启动。
# sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
作用： 禁用 SELinux。
解释： SELinux（Security-Enhanced Linux）会限制一些操作，关闭它可以避免可能的安全策略冲突。通过 sed 命令修改 /etc/selinux/config 文件，将 SELinux 设置为 disabled。
# init 6
作用： 重启系统。
解释： 这会重新启动系统，确保在禁用 SELinux 后应用配置。
# setenforce 0
作用： 临时禁用 SELinux（只在当前会话有效）。
解释： 这会立即禁用 SELinux 的强制执行模式，允许你执行本次操作。
# dnf -y install cobbler dhcp-server
作用： 安装 Cobbler 和 DHCP 服务器。
解释： Cobbler 是用于配置 PXE 启动的工具，而 dhcp-server 用于提供动态主机配置协议（DHCP），让网络中的客户端可以自动获取 IP 地址。
# openssl passwd -1
作用： 使用 openssl 生成加密的密码。
解释： 生成一个基于 MD5 的加密密码，通常用于设置用户账户密码。
# vi /etc/cobbler/settings.yaml
作用： 编辑 Cobbler 的配置文件。
解释： 配置文件 settings.yaml 包含了 Cobbler 的全局设置，例如 PXE 服务器的 IP 地址、认证等。
# vi /etc/cobbler/dhcp.template
作用： 编辑 Cobbler 的 DHCP 配置模板。
解释： dhcp.template 文件用于配置 Cobbler 与 DHCP 服务器的交互，通常用于设置 DHCP 范围、PXE 启动等参数。
# systemctl enable --now cobblerd
作用： 启动并使 cobblerd 服务开机自启。
解释： 这会启动 Cobbler 服务，并将其设置为开机自启。
# cobbler sync
作用： 同步 Cobbler 配置。
解释： 执行此命令会使 Cobbler 重新加载配置并应用更改，确保所有设置生效。
# systemctl enable --now tftp httpd dhcpd
作用： 启动并使 tftp, httpd, dhcpd 服务开机自启。
解释： 这些服务是 PXE 启动所需的：tftp 提供文件传输服务，httpd 提供 HTTP 服务，dhcpd 提供 DHCP 服务。
# cobbler check
作用： 检查 Cobbler 配置和系统状态。
解释： 这个命令会帮助你识别配置中的潜在问题，例如缺少的依赖项或配置错误。
# dnf -y install syslinux dnf-plugins-core pykickstart
作用： 安装 syslinux, dnf-plugins-core, 和 pykickstart。
解释： syslinux 是一个支持 PXE 引导的引导程序，dnf-plugins-core 包含 reposync 和 yumdownloader 等工具，pykickstart 是一个用于处理 Kickstart 配置的工具。
# cobbler mkloaders
作用： 生成引导加载程序文件。
解释： 该命令会根据你的配置生成 PXE 启动所需的引导加载程序文件（例如 pxelinux.0）。
# ls /var/lib/cobbler/loaders/
作用： 列出 Cobbler 加载器文件目录中的内容。
解释： 确保 Cobbler 的 PXE 引导程序已经正确生成。
# lsblk
作用： 列出系统的块设备。
解释： 查看系统中所有的硬盘、分区及其挂载情况，确保光盘（/dev/cdrom）和其他设备的状态。
# mount /dev/cdrom /mnt
作用： 将光盘设备挂载到 /mnt 目录。
解释： 用于将安装光盘挂载到文件系统，方便后续的导入操作。
# cobbler import --name=rocky-9-x86_64 --path=/mnt/ --arch=x86_64
作用： 导入操作系统镜像。
解释： 该命令从挂载的光盘路径 /mnt 导入 Rocky Linux 9 的镜像文件，给该镜像指定一个名字 rocky-9-x86_64。
# cobbler distro list
作用： 列出所有导入的操作系统。
解释： 查看已经导入的操作系统镜像列表，确认 rocky-9-x86_64 是否已成功导入。
# systemctl restart cobblerd
作用： 重启 cobblerd 服务。
解释： 重新启动 Cobbler 服务，确保任何更改都能生效。
# cobbler sync
作用： 同步 Cobbler 配置。
解释： 确保所有配置都同步并生效。
# cat /var/lib/tftpboot/pxelinux.cfg/default
作用： 查看 PXE 配置文件。
解释： 查看 pxelinux.cfg/default 文件，确认 PXE 启动配置是否正确。
# vim /var/lib/cobbler/templates/rocky9.ks
作用： 编辑 Rocky Linux 9 的 Kickstart 配置文件。
解释： 使用 vim 编辑 Kickstart 文件，用于定义自动安装过程。
# cobbler profile remove --name rocky-9-x86_64
作用： 删除现有的 rocky-9-x86_64 配置文件。
解释： 删除现有的配置，可能是因为要重新配置。
# cobbler profile add --name rocky-9-x86_64 --distro=rocky-9-x86_64 --autoinstall=rocky9.ks
作用： 添加新的配置文件。
解释： 为 rocky-9-x86_64 镜像创建一个新的配置文件，指定 rocky9.ks 为自动安装脚本。
# systemctl restart cobblerd
作用： 重启 cobblerd 服务。
解释： 重新启动 Cobbler 服务，确保新配置生效。
# cobbler sync
作用： 同步 Cobbler 配置。
解释： 确保新的配置和设置已经同步到服务器。
# cobbler profile list
作用： 列出所有的配置文件。
解释： 查看当前所有的部署配置文件，确保 rocky-9-x86_64 配置文件已添加。
# vim /var/lib/cobbler/templates/rocky9.ks
作用： 使用 vim 编辑 Cobbler 的 Kickstart 文件 rocky9.ks。
解释： 这个文件是自动化安装 Rocky Linux 9 的配置文件。你可以在这个文件中设置诸如分区、软件包、用户等安装选项。通过编辑该文件，定义自动化部署过程的各个步骤。
# cobbler profile list
作用： 列出 Cobbler 中所有的安装配置文件（Profile）。
解释： 这会显示所有配置文件，配置文件是 Cobbler 用来定义操作系统安装过程的模板。通过此命令可以查看是否已经创建了与 Rocky Linux 9 相关的安装配置文件。
# cobbler profile remove --name rocky-9-x86_64
作用： 删除名为 rocky-9-x86_64 的配置文件。
解释： 如果你之前创建的 rocky-9-x86_64 配置文件有问题，或者你想重新配置，可以通过这个命令删除它。这确保了你不会意外使用旧的或错误的配置文件。
# cobbler profile add --name rocky-9-x86_64 --distro=rocky-9-x86_64 --autoinstall=rocky9.ks
作用： 添加一个新的配置文件（Profile）。
解释： 这个命令为 Cobbler 添加一个新的名为 rocky-9-x86_64 的配置文件，指定该配置文件使用的操作系统镜像是 rocky-9-x86_64，并且使用 rocky9.ks 作为自动安装的 Kickstart 文件。这是一个关键的步骤，确保部署过程按照预定的配置进行。
# cobbler profile list
作用： 再次列出所有的安装配置文件（Profile）。
解释： 这次列出的配置文件应该包含你刚刚添加的 rocky-9-x86_64 配置文件。你可以通过这个命令确认新配置是否已成功添加。
# systemctl restart cobblerd
作用： 重启 cobblerd 服务。
解释： 重启 Cobbler 服务，使得刚刚做出的任何更改（例如添加新的配置文件）生效。确保 Cobbler 能识别到新的配置。
# cobbler sync
作用： 同步 Cobbler 配置。
解释： 执行此命令将更新 Cobbler 的配置和资源，包括所有的镜像、配置文件等。每次修改配置后，都需要执行 cobbler sync 来确保所有改动生效。
~~~



~~~shell
   30  dnf install -y epel-release
   31  systemctl stop firewalld 
   32  systemctl disable firewalld 
   33  sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
   34  init 6
   35  setenforce 0
   36  dnf -y install cobbler dhcp-server
   37  openssl passwd -1
   38  vi /etc/cobbler/settings.yaml
   39  vi /etc/cobbler/dhcp.template
   40  systemctl enable --now cobblerd
   41  cobbler sync
   42  systemctl enable --now tftp httpd dhcpd
   43  cobbler check
   44  dnf -y install syslinux dnf-plugins-core pykickstart
   45  cobbler mkloaders
   46  ls /var/lib/cobbler/loaders/
   47  lsblk 
   48  mount /dev/cdrom /mnt
   49  cobbler import --name=rocky-9-x86_64 --path=/mnt/ --arch=x86_64
   50  cobbler distro list
   51  systemctl restart cobblerd
   52  cobbler sync
   53  cat /var/lib/tftpboot/pxelinux.cfg/default
   54  vim /var/lib/cobbler/templates/rocky9.ks
   55  cobbler profile remove --name rocky-9-x86_64
   56  cobbler profile add --name rocky-9-x86_64 --distro=rocky-9-x86_64 --autoinstall=rocky9.ks
   57  systemctl restart cobblerd
   58  cobbler sync
   59  cobbler profile list
   60  vim /var/lib/cobbler/templates/rocky9.ks
   61  cobbler profile list
   62  cobbler profile remove --name rocky-9-x86_64
   63  cobbler profile add --name rocky-9-x86_64 --distro=rocky-9-x86_64 --autoinstall=rocky9.ks
   64  cobbler profile list
   65  systemctl restart cobblerd
   66  cobbler sync
~~~





