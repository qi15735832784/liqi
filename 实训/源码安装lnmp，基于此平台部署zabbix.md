# 源码安装lnmp，并基于此平台部署zabbix

# zabbix-7.2.3-server

## 安装所需要的依赖包

~~~shell
dnf config-manager --set-enabled crb
dnf clean all
dnf -y install epel-release
dnf install wget git cmake gcc-c++ make openssl-devel pcre-devel zlib-devel libxml2-devel libxslt-devel gd-devel perl-ExtUtils-Embed libmaxminddb-devel gperftools-devel libatomic_ops-devel perl-devel curl-devel libicu-devel oniguruma oniguruma-devel libzip libzip-devel bzip2-devel readline-devel libedit-devel libffi-devel libyaml libyaml-devel sqlite-devel net-snmp-devel libevent-devel openldap-devel langpacks-zh_CN glibc-langpack-zh.x86_64 -y
~~~

## 安装nginx-1.26.3

### 创建运行nginx的组以及用户

~~~shell
groupadd -r nginx
useradd -M -s /bin/false -r -g nginx nginx
~~~

### 下载nginx-1.26.3.tar.gz

~~~shell
cd /usr/src
wget https://nginx.org/download/nginx-1.26.3.tar.gz
~~~

### 解压文件

~~~shell
tar xf nginx-1.26.3.tar.gz
~~~

### 配置

~~~shell
cd nginx-1.26.3/

./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_stub_status_module --with-http_gzip_static_module --with-pcre --with-stream --with-stream_ssl_module --user=nginx --group=nginx
~~~

### 编译，安装

~~~shell
make && make install
~~~

### 创建nginx服务文件

~~~shell
cd /usr/lib/systemd/system/
vim nginx.service 

[Unit]
Description=OpenNginx server daemon
After=network.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp==true

[Install]
WantedBy=multi-user.target
~~~

### 启动服务

~~~shell
systemctl daemon-reload
systemctl start nginx
systemctl enable nginx
~~~

## 安装mysql-8.0.41-linux-glibc2.17-x86_64-minimal.tar.xz

### 创建运行mysql的组以及用户

~~~shell
groupadd -r mysql
useradd -r -g mysql -s /bin/false -M mysql
~~~

### 下载mysql-8.0.41-linux-glibc2.17-x86_64-minimal.tar.xz

~~~shell
cd /usr/src/
wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.41-linux-glibc2.17-x86_64-minimal.tar.xz
~~~

### 解压文件

~~~shell
tar xf mysql-8.0.41-linux-glibc2.17-x86_64-minimal.tar.xz 
~~~

### 移动文件

~~~shell
mv mysql-8.0.41-linux-glibc2.17-x86_64-minimal /usr/local/mysql
~~~

### 给文件赋权

~~~shell
chown -R mysql:mysql /usr/local/mysql
~~~

### 创建数据库目录

~~~shell
mkdir /usr/local/mysql/data
~~~

### 编辑mysql主配置文件

~~~shell
vim /etc/my.cnf

[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
pid-file=/usr/local/mysql/data/mysql.pid
log-error=/usr/local/mysql/data/mysql.err
socket=/tmp/mysql.sock
user=mysql

[client]
socket=/tmp/mysql.sock
~~~

### 将mysql命令添加到系统变量

~~~shell
vim /etc/profile
export MYSQL_HOME=/usr/local/mysql
export PATH=$PATH:$MYSQL_HOME/bin
source /etc/profile
~~~

### 切换目录

~~~shell
cd /usr/local/mysql/
~~~

### 初始化mysql服务

~~~shell
mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
~~~

### 创建mysqld服务文件

~~~shell
vim /usr/lib/systemd/system/mysqld.service

[Unit]
Description=MySQL Server
After=network.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf
ExecReload=/bin/kill -HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
~~~

### 启动服务

~~~shell
systemctl daemon-reload
systemctl start mysqld
systemctl enable mysqld
~~~

### 切换目录

~~~shell
cd data
~~~

### 创建软连接

~~~shell
ln -s /usr/lib64/libncurses.so.6.2 /usr/lib64/libncurses.so.5
ln -s /usr/lib64/libtinfo.so.6.2 /usr/lib64/libtinfo.so.5
~~~

### 查找root用户的临时密码

~~~shell
vim mysql.err
~~~

![image-20250314203101036](https://gitee.com/xiaojinliaqi/img/raw/master/202503142031150.png)

### 登录

~~~shell
mysql -uroot -p yALAU?;#u5SX
~~~

### 给root用户设置密码

~~~shell
alter user root@'localhost' identified by '123';
~~~

## 安装PHP-8.3.17

### 下载php-8.3.17

~~~shell
cd /usr/src
wget https://www.php.net/distributions/php-8.3.17.tar.gz
~~~

### 解压

~~~shell
tar xf php-8.3.17.tar.gz
~~~

### 切换目录

~~~shell
cd php-8.3.17/
~~~

### 配置

~~~shell
./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --enable-fpm --with-fpm-user=nginx --with-fpm-group=nginx --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-openssl --with-zlib --with-curl --enable-gd --with-pear --with-libxml --with-gettext --with-bz2 --with-readline --with-ffi --with-zip --enable-bcmath --enable-mbstring --enable-sockets --with-freetype --with-jpeg
~~~

### 编译，安装

~~~shell
make && make install
~~~

### 复制所需文件

~~~shell
cp php.ini-production /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
~~~

### 赋权

~~~shell
chmod +x -R /usr/local/php/
~~~

### 创建PHP-FPM服务文件

~~~shell
vim /usr/lib/systemd/system/php-fpm.service

[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
Type=simple
PIDFile=/usr/local/php/var/run/php-fpm.pid
ExecStart=/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target
~~~

### 启动服务

~~~shell
systemctl start php-fpm
systemctl enable php-fpm
~~~

### 配置Nginx支持PHP

~~~shell
vim /usr/local/nginx/conf/nginx.conf

        location ~ \.php$ {
            root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
~~~

### 重启服务

~~~shell
systemctl restart nginx
~~~

### 创建网页

~~~shell
vim /usr/local/nginx/html/index.php

<?php
phpinfo();
?>
~~~

### 访问网页，测试php是否联通

![image-20250314204333147](https://gitee.com/xiaojinliaqi/img/raw/master/202503142043240.png)

## 安装Zabbix 7.2.4

### 创建运行zabbix Server的组以及用户

~~~shell
groupadd -r zabbix
useradd -r -M -g zabbix -s /bin/false zabbix
~~~

### 创建Zabbix数据库

~~~shell
mysql -uroot -p123
create database zabbix charset utf8mb4 collate utf8mb4_bin;
~~~

### 创建zabbix用户

~~~shell
create user 'zabbix'@'localhost' identified by 'zabbix';
~~~

### 为zabbix赋予权限

~~~shell
grant all privileges on zabbix.* to 'zabbix'@'localhost';
flush privileges;
~~~

### 下载zabbix-7.2.4.tar.gz

~~~shell
cd /usr/src
wget https://cdn.zabbix.com/zabbix/sources/stable/7.2/zabbix-7.2.4.tar.gz
~~~

### 解压

~~~shell
tar xf zabbix-7.2.4.tar.gz
~~~

### 切换目录

~~~shell
cd zabbix-7.2.4
~~~

### 配置

~~~shell
./configure --prefix=/usr/local/zabbix --enable-server --with-mysql --with-libcurl --with-libxml2 --with-net-snmp --with-openssl --with-ldap
~~~

### 安装

~~~shell
make install
~~~

### 切换目录

~~~shell
cd /usr/src/zabbix-7.2.4/database/mysql
~~~

### 导入zabbix需要的库

~~~shell
mysql -uroot -p zabbix < schema.sql      #-p是需要密码，后面的zabbix是库
mysql -uroot -p zabbix < images.sql
mysql -uroot -p zabbix < data.sql
~~~

### 复制自带的zabbix Server文件

~~~shell
cp -r /usr/src/zabbix-7.2.4/conf/zabbix_server.conf /usr/local/zabbix/etc/zabbix_server.conf
~~~

### 修改zabbix Server的配置文件

~~~shell
vim /usr/local/zabbix/etc/zabbix_server.conf

DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
DBPort=3306
LogFile=/var/log/zabbix/zabbix_server.log
~~~



### 创建日志文件

~~~shell
mkdir /var/log/zabbix/    #服务有问题去看日志，一定要开
~~~

### 赋权

~~~shell
chown -R zabbix:zabbix /usr/local/zabbix/
chmod +x -R /usr/local/zabbix/
chown -R zabbix:zabbix /var/log/ zabbix/zabbix_server.log
~~~

### 启动服务

~~~shell
ln -s /usr/local/mysql/lib/libmysqlclient.so.21 /usr/lib64/
~~~

### 创建zabbix-server服务文件

~~~shell
vim /usr/lib/systemd/system/zabbix-server.service

[Unit]
Description=Zabbix Server
After=network.target mysql.service

[Service]
Type=forking
ExecStart=/usr/local/zabbix/sbin/zabbix_server -c /usr/local/zabbix/etc/zabbix_server.conf
ExecReload=/bin/kill -HUP $MAINPID
User=zabbix
Group=zabbix
Environment="PATH=/usr/local/zabbix/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="LD_LIBRARY_PATH=/usr/local/zabbix/lib:/usr/local/lib:/usr/lib:/lib"

[Install]
WantedBy=multi-user.target
~~~

### 启动服务

~~~shell
systemctl start zabbix-server.service
netstat -anptl
~~~

![image-20250314222156792](https://gitee.com/xiaojinliaqi/img/raw/master/202503142221974.png)



### 配置Zabbix前端

~~~shell
cp -r /usr/src/zabbix-7.2.4/ui/* /usr/local/nginx/html/
~~~

### 配置zabbix使用中文

~~~shell
ln -s /usr/local/php/bin/* /usr/bin/
cd /usr/src/php-8.3.17/ext/gettext
phpize
~~~

![image-20250314223437572](https://gitee.com/xiaojinliaqi/img/raw/master/202503142234655.png)

\#和php一个版本即正确

~~~shell
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
~~~



~~~shell
vim /usr/local/php/etc/php.ini
修改
post_max_size = 16M
max_execution_time = 300
max_input_time = 300
\# 添加或取消注释以下行：
extension=gettext
~~~

### 重启服务

~~~shell
systemctl restart php-fpm
systemctl restart nginx
~~~

## 访问zabbix网页

![image-20250314223922389](https://gitee.com/xiaojinliaqi/img/raw/master/202503142239519.png)

![image-20250314224017413](https://gitee.com/xiaojinliaqi/img/raw/master/202503142240543.png)

![image-20250314224111217](https://gitee.com/xiaojinliaqi/img/raw/master/202503142241325.png)

先下载，然后再放到指定目录

![image-20250314224249699](https://gitee.com/xiaojinliaqi/img/raw/master/202503142242812.png)

![image-20250314224409248](https://gitee.com/xiaojinliaqi/img/raw/master/202503142244328.png)

默认账户Admin，密码zabbix

![image-20250314224527723](https://gitee.com/xiaojinliaqi/img/raw/master/202503142245838.png)

![image-20250314224625237](https://gitee.com/xiaojinliaqi/img/raw/master/202503142246322.png)

![image-20250314224659236](https://gitee.com/xiaojinliaqi/img/raw/master/202503142246368.png)





