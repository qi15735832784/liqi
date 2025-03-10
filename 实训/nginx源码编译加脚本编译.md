# nginx源码编译加脚本编译

## 源码

下载压缩包：https://nginx.org/en/download.html

1.解压 `nginx` 源代码包的命令

~~~shell
tar -zxvf nginx-1.26.3.tar.gz
~~~

2.进入 `nginx-1.26.3/` 目录，该目录是解压后的 `nginx` 源代码目录

~~~shell
cd nginx-1.26.3/
~~~

3.安装编译 `nginx` 所需的开发工具和库

~~~shell
dnf -y install pcre-devel openssl-devel zlib-devel
~~~

4.创建一个名为 `www` 的用户组，和创建一个名为 `www` 的系统用户，并将其加入到 `www` 用户组。

~~~shell
groupadd -r www
useradd -g www -M -s /bin/false -r www
~~~

5.运行 `nginx` 配置脚本，进行自定义配置

~~~shell
./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module --with-http_v2_module  --with-http_addition_module --with-http_sub_module --with-http_flv_module --with-http_mp4_module --with-http_random_index_module --with-http_stub_status_module 
~~~

`./configure`：运行 `nginx` 的配置脚本，以准备编译 `nginx`。

`--prefix=/usr/local/nginx`：指定 `nginx` 安装的路径。

`--user=www`：指定运行 `nginx` 进程的用户为 `www`。

`--group=www`：指定运行 `nginx` 进程的组为 `www`。

`--with-http_ssl_module`：启用 SSL 模块，以支持 HTTPS。

`--with-http_v2_module`：启用 HTTP/2 支持。

`--with-http_addition_module`：启用 `http_addition` 模块，用于在响应中插入额外的内容。

`--with-http_sub_module`：启用 `http_sub` 模块，用于替换响应中的字符串。

`--with-http_flv_module`：启用 `flv` 模块，用于流媒体文件的支持。

`--with-http_mp4_module`：启用 `mp4` 模块，用于支持 MP4 视频流。

`--with-http_random_index_module`：启用随机目录索引模块。

`--with-http_stub_status_module`：启用 `stub_status` 模块，提供 `nginx` 服务器的状态信息。

6.编译并安装 `nginx`。

~~~shell
make && make install
~~~

7.进入 `nginx` 可执行文件所在的目录

~~~shell
cd /usr/local/nginx/sbin
~~~

8.启动 `nginx` 服务

~~~shell
/usr/local/nginx/sbin/nginx 
~~~



![image-20250310171836927](https://gitee.com/xiaojinliaqi/img/raw/master/202503101718080.png)



添加变量

~~~shell
vim /etc/profile
export NGX_HOME=/usr/local/nginx
export PATH=$PATH:$NGX_HOME/sbin

source /etc/profile
~~~



开机自启服务

~~~shell
[root@localhost ~]# vim /usr/lib/systemd/system/nginx.service 
[Unit]
Description=Web server daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
KillMode=process

[Install]
WantedBy=multi-user.target
[root@localhost system]# systemctl daemon-reload
[root@localhost system]# systemctl start nginx
[root@localhost system]# systemctl enable nginx.service 

~~~









脚本编译

~~~shell
#!/bin/bash
#关闭防火墙，沙盒
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
#安装nginx依赖包
dnf -y install zlib-devel openssl-devel pcre-devel
#创建www组以及用户，用来运行nginx
groupadd -r www
useradd -M -g www -r -s /bin/false www
#解压tar包
tar xf nginx-1.26.3.tar.gz -C /usr/src/
#配置nginx
./configure --prefix=/usr/local/nginx --with-http_addition_module --user=www --group=www --with-http_ssl_module --with-http_v2_module --with-http_sub_module --with-http_flv_module --with-http_mp4_module --with-http_random_index_module --with-http_stub_status_module
#编译安装nginx
make && make install
#设置开机启动
cd /usr/lib/systemd/system

cp sshd.service nginx.service

cat > nginx.service <<EOF
[Unit]
Description=web server daemon
After=network.target 

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl start nginx
systemctl enable nginx
~~~











