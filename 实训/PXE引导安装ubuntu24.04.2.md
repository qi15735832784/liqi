# PXE引导安装ubuntu24.04.2

## PXE服务器，让客户端通过网络引导操作系统

### 1.禁用防火墙和SELinux

~~~shell
#停止并禁用防火墙，以避免防火墙阻止PXE相关的网络通信
systemctl stop firewalld
systemctl disable firewalld

#禁用SELinux，以确保没有与PXE服务器相关的权限问题
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

#重启系统，使防火墙和SELinux的更改生效
init 6

#依次验证
getenforce 
systemctl status firewalld
~~~

![image-20250307154632789](https://gitee.com/xiaojinliaqi/img/raw/master/202503071546939.png)

### 2.安装必要的包

~~~shell
#安装EPEL（Extra Packages for Enterprise Linux）仓库，以便获得一些额外的软件包
yum -y install epel-release

#它是一个提供DHCP和TFTP服务的工具，PXE需要通过它来分配IP地址和提供启动文件
yum -y install dnsmasq

#安装Apache Web服务器（httpd）来提供ISO镜像和启动文件，
yum -y install httpd 

#安装syslinux包提供PXE引导程序文件，如pxelinux.0
yum -y install syslinux
~~~

![image-20250307154926458](https://gitee.com/xiaojinliaqi/img/raw/master/202503071549500.png)

### 3.配置dnsmasq

~~~shell
#配置 dnsmasq 用于PXE启动。这些配置通常包括设置DHCP选项和TFTP路径
vim /etc/dnsmasq.conf 
修改
interface=ens160              # 监听网卡接口    
bind-interfaces               # 强制绑定到指定接口   
port=5353                     # DNS端口（避免与systemd-resolved冲突） 
dhcp-range=192.168.8.50,192.168.8.150,12h  # DHCP地址范围和租约时间    
dhcp-boot=pxelinux.0          # 指定PXE引导文件    
enable-tftp                   # 启用TFTP服务    
tftp-root=/srv/tftp           # TFTP根目录    
log-facility=/var/log/dnsmasq.log  # 日志路径，这个没有自己添加，位置随便
~~~

### 4.创建TFTP目录并重启 dnsmasq 服务

~~~shell
#/srv/tftp 是存放PXE启动文件的目录。-p选项确保如果目录不存在，会自动创建
mkdir -p /srv/tftp

#重启 dnsmasq 服务，以便加载新的配置文件和TFTP服务
systemctl restart dnsmasq
~~~

![image-20250307160148364](https://gitee.com/xiaojinliaqi/img/raw/master/202503071601402.png)

### 5.检查网络服务

~~~shell
#显示当前系统所有的网络连接，包括UDP和TCP端口的使用情况
netstat -anptu
~~~

![image-20250307160455292](https://gitee.com/xiaojinliaqi/img/raw/master/202503071604338.png)

### 6.配置 HTTP 服务器

~~~shell
#Apache 默认的 Web 服务器根目录通常是 /var/www/html/
cd /var/www/html/

#创建 autoinstall 和 iso 目录：autoinstall 目录通常用于存放自动化安装的配置文件，iso 用来存放ISO镜像文件
mkdir autoinstall iso

#创建 meta-data 文件：这是一个空文件，通常在自动化安装中用于存储元数据，像是安装源的配置
touch autoinstall/meta-data

#创建 user-data 文件：这是另一个空文件，用于存储用户自定义的安装配置，如自动化安装的设置
touch autoinstall/user-data

#移动 ISO 文件：将下载的Ubuntu ISO镜像文件移动到iso/目录中
mv ubuntu-24.04.2-live-server-amd64.iso iso/
~~~

![image-20250307160109409](https://gitee.com/xiaojinliaqi/img/raw/master/202503071603878.png)

### 7.配置自动化安装配置

~~~shell
#使用 SHA-512 算法生成密码的哈希值,在密码学中，-6 是指采用 SHA-512 算法来加密密码，这是 Linux 系统中常用的一种加密方式
[root@localhost ~]# openssl passwd -6
Password: 123.com
Verifying - Password: 123.com
$6$e0nnHhT8GbZ6Tygs$F5B61oGBun71j7WQwasWvwi9T3k8t5/fxkNDUzlOKLed8Ez3bhGHmq29duUOVHSiMFthglr5DRLLlAf7GRJSf.

#编辑 user-data 文件,用 vim 编辑 user-data 文件，添加自动安装的配置
[root@localhost ~]# vim /var/www/html/autoinstall/user-data 
#cloud-config
autoinstall:
  version: 1
  # 设置语言
  locale: en_US.UTF-8
  # 设置时区
  timezone: Asia/Shanghai
  keyboard:
    layout: us
  # 安装ubuntu服务器版，最小化选择 ubuntu-mini
  source:
    id: ubuntu-server
    search_drivers: false
  # 网络配置,根据具体接口名称修改。
  network:
    version: 2
    ethernets:
      ens33: {dhcp4: true}
  # 是否安装第三方驱动
  drivers:
    install: false
  # 内核安装，linux-generic 通用内核
  kernel:
    package: linux-generic
  # 设置存储库，这里使用阿里云
  apt:
    fallback: offline-install
    mirror-selection:
      primary:
      - arches: [amd64]
        uri: http://mirrors.aliyun.com/ubuntu/
      - arches: [arm64]
        uri: http://mirrors.aliyun.com/ubuntu-ports
    preserve_sources_list: false
  # 配置存储，分区
  storage:
    config:
    - {ptable: gpt, path: /dev/sda, wipe: superblock-recursive, preserve: false, name: '', grub_device: true,type: disk, id: disk-sda}
    - {device: disk-sda, size: 1M, flag: bios_grub, number: 1, preserve: false,type: partition, id: partition-0}
    - {device: disk-sda, size: 300M, wipe: superblock, flag: '', number: 2,preserve: false, type: partition, id: partition-1}
    - {device: disk-sda, size: -1, wipe: superblock, flag: '', number: 3, preserve: false, type: partition, id: partition-2}
    - {fstype: ext4, volume: partition-1, preserve: false, type: format, id: format-0}
    - {fstype: ext4, volume: partition-2, preserve: false, type: format, id: format-1}
    - {device: format-0, path: /boot, type: mount, id: mount-0}
    - {device: format-1, path: /, type: mount, id: mount-1}
  # 配置账号信息
  identity:
    hostname: ubuntu
    username: ubuntu
    password: $6$e0nnHhT8GbZ6Tygs$F5B61oGBun71j7WQwasWvwi9T3k8t5/fxkNDUzlOKLed8Ez3bhGHmq29duUOVHSiMFthglr5DRLLlAf7GRJSf.
  # ssg 配置
  ssh:
    allow-pw: true
    install-server: true
  # 软件安装
  packages:
    - vim
    - git
  # 重启前要运行的命令，curtin in-target --target=/target -- $shell_commandcurtin 格式
  late-commands:
    - curtin in-target --target=/target -- apt-get -y update

#启动Apache Web服务器，确保可以通过HTTP访问安装文件
systemctl start httpd

#设置 httpd 服务开机启动：确保httpd服务在系统重启后自动启动
systemctl enable httpd
~~~

确保web服务器正常运行，可以访问到 iso 和 autoinstaller目录下的文件

![image-20250307161522995](https://gitee.com/xiaojinliaqi/img/raw/master/202503071615045.png)

![image-20250307161606157](https://gitee.com/xiaojinliaqi/img/raw/master/202503071616212.png)

### 8.挂载 ISO 文件并复制启动文件

~~~shell
#挂载 ISO 镜像：将Ubuntu ISO文件挂载到 /mnt 目录，用于提取文件
mount -o loop /var/www/html/iso/ubuntu-24.04.2-live-server-amd64.iso /mnt

#复制内核和初始化RAM盘文件：从ISO的casper目录中复制内核（vmlinuz）和初始化RAM盘（initrd）到 /srv/tftp/ 目录，用于PXE启动
cp /mnt/casper/{vmlinuz,initrd} /srv/tftp/
~~~

![image-20250307161927284](https://gitee.com/xiaojinliaqi/img/raw/master/202503071619329.png)

### 9.准备 PXE 引导文件

~~~shell
#列出 TFTP 目录：查看 /srv/tftp/ 目录，确认内核和初始化RAM盘文件是否已经复制
[root@localhost html]# ls /srv/tftp/

#解压 Netboot 文件,将 ubuntu-24.04.2-netboot-amd64.tar.gz 文件解压，提取包含 PXE 启动所需的文件
tar -zxvf ubuntu-24.04.2-netboot-amd64.tar.gz

#复制 pxelinux.0 引导程序：将解压后的 pxelinux.0 文件复制到 /srv/tftp/ 目录，它是PXE引导程序的关键文件
cp /root/amd64/pxelinux.0 /srv/tftp/
~~~

![image-20250307162256467](https://gitee.com/xiaojinliaqi/img/raw/master/202503071622526.png)

![image-20250307162201090](https://gitee.com/xiaojinliaqi/img/raw/master/202503071622137.png)

![image-20250307162600883](https://gitee.com/xiaojinliaqi/img/raw/master/202503071626937.png)

### 10.配置 PXE 引导选项

~~~shell
#切换到 TFTP 目录：进入 /srv/tftp/ 目录
cd /srv/tftp/

#创建一个名为 pxelinux.cfg 的目录。这个目录用于存放 PXE 启动的配置文件。通常该目录包含启动菜单、系统选项等
mkdir -p pxelinux.cfg

#编辑 default 配置文件，该文件位于 pxelinux.cfg/ 目录下。这个文件通常用来设置 PXE 启动菜单的配置，例如操作系统的启动选项、内核和初始化文件的位置
vim /srv/tftp/pxelinux.cfg/default
添加
DEFAULT menu.c32
MENU TITLE PXE Boot Menu
PROMPT 0
TIMEOUT 30

LABEL Ubuntu 24.04 BIOS Install
    MENU LABEL Install Ubuntu 24.04 (BIOS)
    KERNEL vmlinuz
    INITRD initrd
APPEND root=/dev/ram0 ramdisk_size=1024 ip=dhcp url=http://10.15.200.100/iso/ubuntu-24.04.2-live-server-amd64.iso autoinstall ds=nocloud-net;s=http://10.15.200.100/autoinstall/ cloud-config-url=/dev/null
~~~

![image-20250307163604245](https://gitee.com/xiaojinliaqi/img/raw/master/202503071636288.png)

![image-20250307163654124](https://gitee.com/xiaojinliaqi/img/raw/master/202503071636182.png)

### 11.拷贝所需的文件到tftp工作目录下

~~~shell
#将 ldlinux.c32 文件复制到 /srv/tftp/ 目录中。ldlinux.c32 是 syslinux 启动加载程序的一部分，用于启动和加载系统
cp /usr/share/syslinux/ldlinux.c32 /srv/tftp/

#将 libutil.c32 文件复制到 /srv/tftp/ 目录中。这个文件是 syslinux 启动所需要的库文件，提供了额外的功能
cp /usr/share/syslinux/libutil.c32 /srv/tftp/

#将 menu.c32 文件复制到 /srv/tftp/ 目录中。menu.c32 是一个提供图形化菜单界面的文件，可以在 PXE 启动时提供可选择的操作系统启动项
cp /usr/share/syslinux/menu.c32 /srv/tftp/

#列出 /srv/tftp/ 目录的文件，以确保所需的所有文件（如 pxelinux.0、ldlinux.c32、libutil.c32、menu.c32 等）都已成功复制并放置在该目录中
ls /srv/tftp/
~~~

![image-20250307163508453](https://gitee.com/xiaojinliaqi/img/raw/master/202503071635503.png)



### 12.开始部署

新建虚拟机就会自动部署，加以等待就会自动部署完成

![image-20250307164200576](https://gitee.com/xiaojinliaqi/img/raw/master/202503071642689.png)







