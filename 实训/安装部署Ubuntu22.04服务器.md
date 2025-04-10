# 安装部署Ubuntu22.04服务器

##  1.准备Ubuntu镜像
aaaaa

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



# 自动化部署

## 操作步骤详解讲解

~~~shell
1. mkdir -p /mnt/ubuntu22
作用：创建一个目录 /mnt/ubuntu22，用于挂载 Ubuntu 22.04 的 ISO 镜像。
-p 参数表示如果路径中有不存在的目录，它会自动创建。
这个命令确保有一个目标目录来挂载 ISO 文件。
2. mount /root/ubuntu-22.04-live-server-amd64.iso /mnt/ubuntu22/
作用：将位于 /root/ubuntu-22.04-live-server-amd64.iso 的 Ubuntu 22.04 ISO 镜像挂载到 /mnt/ubuntu22/ 目录。
这样就可以在 /mnt/ubuntu22/ 目录下访问 ISO 文件中的内容。
3. cobbler import --name=ubuntu-22 --path=/mnt/ubuntu22/
作用：使用 Cobbler 将 /mnt/ubuntu22/ 中的 Ubuntu 22.04 ISO 文件导入为一个新的安装镜像。
--name=ubuntu-22：为导入的镜像指定一个名字（在这里是 ubuntu-22）。
这个命令会将 ISO 文件中的内容（如包和安装文件）导入到 Cobbler 中，供 PXE 网络安装使用。
4. cobbler distro list
作用：列出已在 Cobbler 中导入的所有操作系统发行版（distro）。
这个命令将展示当前 Cobbler 配置中可用的操作系统镜像。
5. cobbler profile list
作用：列出在 Cobbler 中为不同发行版创建的安装配置文件（profile）。
配置文件描述了如何安装操作系统（包括分区、包选择等）。这对于每个导入的发行版是必需的。
6. systemctl restart cobblerd
作用：重新启动 Cobbler 服务（cobblerd）。
这个命令确保任何修改（例如导入新的操作系统镜像）在 Cobbler 服务中生效。
7. cobbler sync
作用：同步 Cobbler 配置，确保所有修改都更新到配置文件和服务中。
这会将导入的操作系统、配置文件等更新到 PXE 启动环境和 DHCP 配置中，使网络安装能够正常工作。
8. cat /var/lib/tftpboot/pxelinux.cfg/default
作用：查看 /var/lib/tftpboot/pxelinux.cfg/default 文件的内容。
该文件是 Cobbler 和 PXE 启动时使用的配置文件，包含了启动菜单的设置。这个文件定义了通过 PXE 启动时的菜单选项，告诉系统如何加载操作系统和引导安装。
9. ls /var/lib/cobbler/templates/
作用：列出 /var/lib/cobbler/templates/ 目录中的文件。
这个目录包含了用于自动化安装的模板文件。比如 ubuntu.seed 就是一个用于 Ubuntu 安装的模板文件。
10. vim /var/lib/cobbler/templates/ubuntu.seed
作用：使用 vim 编辑器打开 /var/lib/cobbler/templates/ubuntu.seed 文件。
这个文件是 Ubuntu 安装过程中使用的预设文件（Preseed）。你可以在其中配置安装时的一些选项，例如分区、网络设置和软件包选择等。修改此文件可以定制 Ubuntu 的自动安装过程。


1. cobbler profile list
作用：列出当前在 Cobbler 中配置的所有 安装配置文件（Profiles）。
配置文件用于定义特定操作系统安装过程中的设置，例如自动化安装的 preseed 文件、分区、软件包选择等。
2. cobbler profile remove --name ubuntu-22-casper-x86_64
作用：删除名为 ubuntu-22-casper-x86_64 的安装配置文件。
如果你不再需要这个配置文件，或者希望为其创建一个新的配置文件，可以使用这个命令将其删除。
3. cobbler profile add --name ubuntu-casper-x86_64 --distro=ubuntu-22-casper-x86_64 --autoinstall=ubuntu.seed
作用：创建一个新的安装配置文件 ubuntu-casper-x86_64，并关联到 Ubuntu 22.04 的发行版 ubuntu-22-casper-x86_64，同时指定一个 autoinstall 文件（在这里是 ubuntu.seed）。
--distro=ubuntu-22-casper-x86_64：为新的配置文件指定一个操作系统发行版（ubuntu-22-casper-x86_64）。
--autoinstall=ubuntu.seed：指定一个自动化安装文件（ubuntu.seed），这个文件通常包含了安装过程中的各种预设选项，如分区、语言、时区等。
4. systemctl restart cobblerd.service
作用：重新启动 Cobbler 服务 (cobblerd)。
这是确保所有更改（如创建或删除配置文件）生效的步骤。通过重新启动服务，Cobbler 会重新加载配置。
5. cobbler sync
作用：同步所有 Cobbler 配置。
该命令确保任何更改（如添加新配置文件或修改配置）都会更新到实际的网络环境中，包括 PXE 配置、DHCP 配置等。同步后的更改会立即生效。
6. cobbler profile list
作用：再次列出当前在 Cobbler 中配置的所有安装配置文件。
这可以帮助你验证配置文件是否已经成功添加或删除。例如，你应该看到新的配置文件 ubuntu-casper-x86_64 列在输出中，替代了之前的 ubuntu-22-casper-x86_64。
~~~



## 操作步骤

~~~shell
mkdir -p /mnt/ubuntu22
mount /root/ubuntu-22.04-live-server-amd64.iso /mnt/ubuntu22/
cobbler import --name=ubuntu-22 --path=/mnt/ubuntu22/
cobbler distro list 
cobbler profile list 
systemctl restart cobblerd
cobbler sync
cat /var/lib/tftpboot/pxelinux.cfg/default
ls /var/lib/cobbler/templates/
vim /var/lib/cobbler/templates/ubuntu.seed
添加
d-i debian-installer/locale string en_US.UTF-8


d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select us
d-i keyboard-configuration/toggle select No toggling
d-i keyboard-configuration/layoutcode string us
d-i keyboard-configuration/variantcode string




d-i time/zone string Asia/Shanghai
d-i clock-setup/ntp-server string ntp1.aliyun.com
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true


# Setup the installation source
d-i mirror/country string manual
d-i mirror/http/hostname string 10.15.200.100
d-i mirror/http/directory string  /mnt
d-i mirror/http/proxy string


d-i live-installer/net-image string http://$http_server/cobbler/links/$distro_name/install/filesystem.squashfs




d-i partman-auto/disk string /dev/sda
d-i partman-auto/choose_recipe select atomic
d-i partman-auto/method string lvm
d-i partman-auto-lvm/guided_size string 100%
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-partitioning/confirm_write_new_ label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/default_filesystem string ext4
d-i partman/mount_style select uuid
# You can choose one of the three predefined partitioning recipes:
# - atomic: all files in one partition
# - home:   separate /home partition
# - multi:  separate /home, /usr, /var, and /tmp partitions
d-i partman-auto/choose_recipe select atomic


d-i passwd/root-login boolean true
d-i passwd/root-password-crypted password $1$RcOmy101$lw0TpqbMlxzijQjyXuAqj0


d-i passwd/make-user boolean false


d-i apt-setup/restricted boolean true
d-i apt-setup/universe boolean true
d-i apt-setup/backports boolean true


d-i apt-setup/services-select multiselect security
d-i apt-setup/security_host string mirrors.aliyun.com
d-i apt-setup/security_path string /ubuntu

$SNIPPET('preseed_apt_repo_config')


tasksel tasksel/first multiselect standard

d-i pkgsel/include string openssh-server vim


d-i grub-installer/grub2_instead_of_grub_legacy boolean true
d-i grub-installer/bootdev string /dev/sda
#end if


d-i debian-installer/add-kernel-opts string $kernel_options_post


d-i finish-install/reboot_in_progress note


d-i preseed/early_command string wget -O- \
   http://$http_server/cblr/svc/op/script/$what/$name/?script=preseed_early_default | \
      /bin/sh -s

      d-i preseed/late_command string wget -O- \
         http://$http_server/cblr/svc/op/script/$what/$name/?script=preseed_late_default | \
            chroot /target /bin/sh -s

cobbler profile list
cobbler profile remove --name ubuntu-22-casper-x86_64
cobbler profile add --name ubuntu-casper-x86_64 --distro=ubuntu-22-casper-x86_64 --autoinstall=ubuntu.seed
systemctl restart cobblerd.service
cobbler sync 
cobbler profile list 

~~~

# 应答文件讲解

1. **语言与键盘配置**
2. **时区与时间同步配置**
3. **安装源配置**
4. **分区与磁盘管理**
5. **用户与密码配置**
6. **APT 软件源配置**
7. **包选择与安装**
8. **GRUB 引导程序安装**
9. **自定义脚本的执行**

### 1. **语言与键盘配置**

```shell
d-i debian-installer/locale string en_US.UTF-8
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select us
d-i keyboard-configuration/toggle select No toggling
d-i keyboard-configuration/layoutcode string us
d-i keyboard-configuration/variantcode string
```

- 这部分设置操作系统的语言环境和键盘布局
	- 设置为 **英文** (`en_US.UTF-8`)。
	- 设置 **美国键盘布局** (`us`)。

### 2. **时区与时间同步配置**

```shell
d-i time/zone string Asia/Shanghai
d-i clock-setup/ntp-server string ntp1.aliyun.com
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true
```

- 设置 **时区** 为 **上海**（`Asia/Shanghai`）。
- 配置 **NTP 服务器** 为 `ntp1.aliyun.com`，用于时间同步。
- 使用 **UTC 时间** 格式。

### 3. **安装源配置**

```shell
d-i mirror/country string manual
d-i mirror/http/hostname string 10.15.200.100
d-i mirror/http/directory string  /mnt
d-i mirror/http/proxy string
```

- 配置安装源：
	- 使用 **手动配置** 的方式指定源。
	- 安装镜像文件源地址是 `10.15.200.100`，并且镜像存放在 `/mnt` 目录。

```shell
d-i live-installer/net-image string http://$http_server/cobbler/links/$distro_name/install/filesystem.squashfs
```

- 配置网络安装源，使用指定的 URL 地址来下载文件系统。

### 4. **分区与磁盘管理**

```shell
d-i partman-auto/disk string /dev/sda
d-i partman-auto/choose_recipe select atomic
d-i partman-auto/method string lvm
d-i partman-auto-lvm/guided_size string 100%
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/default_filesystem string ext4
d-i partman/mount_style select uuid
```

- 设置磁盘分区、LVM 逻辑卷管理（LVM）和文件系统：
	- 使用 **LVM** 管理磁盘，选择 `atomic` 分区布局，所有分区都在一个磁盘中。
	- 使用 **ext4** 文件系统格式。
	- 确保 **确认写入分区表**。

### 5. **用户与密码配置**

```shell
d-i passwd/root-login boolean true
d-i passwd/root-password-crypted password $1$RcOmy101$lw0TpqbMlxzijQjyXuAqj0
d-i passwd/make-user boolean false
```

- **启用 root 登录** 并设置 root 密码（使用加密密码）。
- **不创建普通用户**，只启用 root 用户。

### 6. **APT 软件源配置**

```shell
d-i apt-setup/restricted boolean true
d-i apt-setup/universe boolean true
d-i apt-setup/backports boolean true
d-i apt-setup/services-select multiselect security
d-i apt-setup/security_host string mirrors.aliyun.com
d-i apt-setup/security_path string /ubuntu
```

- 启用 **restricted、universe** 和 **backports** 软件源。
- 设置 **安全源** 使用 `mirrors.aliyun.com`，这是阿里云的镜像源。

### 7. **包选择与安装**

```shell
d-i pkgsel/include string openssh-server vim
```

- 安装 **OpenSSH 服务** 和 **Vim 编辑器**。

### 8. **GRUB 引导程序安装**

```shell
d-i grub-installer/grub2_instead_of_grub_legacy boolean true
d-i grub-installer/bootdev string /dev/sda
```

- 安装 **GRUB2** 引导程序，并指定引导设备为 `/dev/sda`。

### 9. **自定义脚本的执行**

```shell
d-i preseed/early_command string wget -O- \
   http://$http_server/cblr/svc/op/script/$what/$name/?script=preseed_early_default | \
      /bin/sh -s

d-i preseed/late_command string wget -O- \
   http://$http_server/cblr/svc/op/script/$what/$name/?script=preseed_late_default | \
      chroot /target /bin/sh -s
```

- 在安装过程中，执行自定义脚本
	- **早期命令**：在安装开始时执行。
	- **晚期命令**：在系统安装完毕后执行。

