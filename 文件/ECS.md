# ECS

## 1.硬盘在线扩容

![image-20240925163359870](https://gitee.com/xiaojinliaqi/img/raw/master/202409251634014.png)

![](https://gitee.com/xiaojinliaqi/img/raw/master/202409251646472.png)

![image-20240925170456403](https://gitee.com/xiaojinliaqi/img/raw/master/202409251704679.png)



## 2.快照

![image-20240925174252513](https://gitee.com/xiaojinliaqi/img/raw/master/202409251742790.png)

![image-20240925174337723](https://gitee.com/xiaojinliaqi/img/raw/master/202409251743993.png)



## 3.自定义镜像

![image-20240925174430528](https://gitee.com/xiaojinliaqi/img/raw/master/202409251744794.png)

![image-20240925174528044](https://gitee.com/xiaojinliaqi/img/raw/master/202409251745329.png)



## 4.弹性扩容

![image-20240925174839249](https://gitee.com/xiaojinliaqi/img/raw/master/202409251748319.png)

![image-20240925174756778](https://gitee.com/xiaojinliaqi/img/raw/master/202409251747077.png)



## 5.必须完成：安装LNMP环境，mysql为阿里云的RDS。安装wordpress进行测试

下载最新的软件包元数据

~~~shell
yum makecache
~~~

安装以下组件：

- `php`: PHP 核心包。
- `php-cli`: PHP 命令行界面。
- `php-pear`: PHP Extension and Application Repository (PEAR) 安装器。
- `php-bcmath`: 提供对大数计算的支持。
- `php-fpm`: PHP FastCGI 进程管理器。
- `php-mysqlnd`: MySQL 数据库驱动程序。
- `php-zip`: ZIP 文件支持。
- `php-gd`: 图形绘制功能。
- `php-mbstring`: 多字节字符串处理。
- `php-xml`: XML 支持。
- `php-ldap`: LDAP 协议支持。
- `php-intl`: 国际化和本地化支持。
- `php-opcache`: PHP OPcode 缓存优化。

~~~shell
yum -yq install php php-cli p-pear php-bcmath php-hp-fpm php-mysqlnd php-zip php-gd php-mbstring php-xml php-pear php-bcmath php-ldap php-intl php-opcache
~~~

下载nginx

~~~shell
[root@server01 ~]# ls
nginx-1.26.0.tar.gz
[root@server01 ~]# tar -zxf nginx-1.26.0.tar.gz 
[root@server01 ~]# cd nginx-1.26.0/
~~~

安装依赖

~~~shell
yum -y install gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel
~~~

配置

~~~shell
./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin
~~~

编译

~~~shell
make -j2 && make install
~~~

配置/etc/php-fpm.d/www.conf文件

~~~shell
vim /etc/php-fpm.d/www.conf
修改配置文件
[www]
user = nginx
group = nginx
listen = /run/php-fpm/www.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
listen.allowed_clients = 127.0.0.1
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
slowlog = /var/log/php-fpm/www-slow.log
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
~~~

创建用户账户

~~~shell
useradd nginx
~~~

启动php-fpm

~~~shell
systemctl start php-fpm
systemctl status php-fpm
~~~

编辑nginx配置文件

~~~shell
[root@server01 nginx]# cat /etc/nginx/nginx.conf
user nginx;
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.php;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
        location ~ \.php$ {
            root           /nginx/;
            fastcgi_pass   unix:/run/php-fpm/www.sock;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $request_filename;
            include        fastcgi_params;
        }
    }
}
~~~

查看nginx语法是否正确，然后启动

~~~shell
nginx -t 
nginx
~~~

编辑PHP默认页面

~~~shell
[root@server01 nginx-1.26.0]# cd /nginx/
[root@server01 nginx]# vim index.php
<?php
phpinfo();
?>
[root@server01 nginx]# php index.php 
~~~

访问公网ip（访问的是PHP默认页面）

~~~shell
http://101.201.38.127/index.php
~~~

最后删除index.php即可

阿里购买数据库

买完之后创建账号

![image-20240926225144447](https://gitee.com/xiaojinliaqi/img/raw/master/202409262251573.png)

创建数据库

![image-20240926225310736](https://gitee.com/xiaojinliaqi/img/raw/master/202409262253839.png)

给创建好的账户设置权限

![image-20240926225430764](https://gitee.com/xiaojinliaqi/img/raw/master/202409262254883.png)

![image-20240926225509699](https://gitee.com/xiaojinliaqi/img/raw/master/202409262255822.png)

数据库连接里有内网地址

![image-20240926225835402](https://gitee.com/xiaojinliaqi/img/raw/master/202409262258545.png)

尝试登陆数据库

~~~shell
[root@server01 ~]# mysql -ulq -pLq040212 -h rm-2ze654b28o91vj565.mysql.rds.aliyuncs.com
~~~



拉取wordpress包

~~~shell
tar -zxf wordpress-6.2.tar.gz -C /nginx/
cd /nginx/
cp wp-config-sample.php wp-config.php
rm -rf wp-config-sample.php
~~~

~~~shell
yum -y install mysql
~~~

修改wordpress

~~~shell
cd /nginx/
vim wp-config.php
修改
/** The name of the database for WordPress */
define( 'DB_NAME', 'nginx' );   #阿里云RDS数据库
/** Database username */
define( 'DB_USER', 'lq' );   #阿里云RDS数据库账号
/** Database password */
define( 'DB_PASSWORD', 'Lq040212' );   #阿里云RDS数据库密码
/** Database hostname */
define( 'DB_HOST', 'rm-2ze654b28o91vj565.mysql.rds.aliyuncs.com' );   #阿里云RDS数据库内网地址
~~~

~~~shell
访问 101.201.38.127
~~~

![image-20240926230356590](https://gitee.com/xiaojinliaqi/img/raw/master/202409262303657.png)

要是404 的话解决办法如下

![image-20240926230935910](https://gitee.com/xiaojinliaqi/img/raw/master/202409262309062.png)

然后重启nginx服务

~~~shell
nginx -s reload
~~~

最后再次访问（注意路径）

~~~shell
http://101.201.38.127/wp-admin/index.php
~~~

![image-20240926231128641](https://gitee.com/xiaojinliaqi/img/raw/master/202409262311725.png)
