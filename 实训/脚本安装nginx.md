脚本安装nginx

准备nginx压缩包，在官网直接下载

~~~shell
wget http://nginx.org/download/nginx-1.24.0.tar.gz
wget http://nginx.org/download/nginx-1.26.0.tar.gz
wget http://nginx.org/download/nginx-1.27.0.tar.gz
~~~



编写脚本

~~~shell
vim nginx.sh
#!/bin/bash

#判断操作系统
os=$(awk -F'=' '/^NAME/ {print $2}' /etc/os-release |tr -d '"')
echo "您的操作系统的发行版本是:$os"

#选择版本
read -p "请您选择要安装的nginx版本[nginx-1.24|nginx-1.26|nginx-1.27]: " nginx
case $os in
"Rocky Linux")
        dnf -y install epel-release
        dnf makecache
        dnf -y install pcre-devel openssl-devel zlib
;;
"Ubuntu")
        apt -y install epel-release
        apt makecach
        apt -y install pcre-devel openssl-devel zli
;;
*)
        echo "下载依赖失败"
        exit;;
esac


        # 关闭防火墙
        systemctl stop firewalld
        systemctl disable firewalld
        # 创建用户，解压，配置，安装
        useradd nginx -s /bin/false -M

case ${nginx} in 
nginx-1.24)
        tar xf nginx-1.24.0.tar.gz
        cd nginx-1.24.0
;;
nginx-1.26)
        tar xf nginx-1.26.0.tar.gz
        cd nginx-1.26.0
;;
nginx-1.27)
        tar xf nginx-1.27.0.tar.gz
        cd nginx-1.27.0 
;;
*)
        echo "解压失败"
        exit;;
esac

        ./configure --prefix=/usr/local/nginx \
                --user=nginx \
                --group=nginx \
                --without-http_rewrite_module\
                --with-http_ssl_module \
                --with-http_v2_module \
                --with-http_addition_module \
                --with-http_sub_module \
                --with-http_flv_module \
                --with-http_mp4_module \
                --with-http_random_index_module \
                --with-http_stub_status_module
        make && make install
        /usr/local/nginx/sbin/nginx
        echo "${os}-${nginx}已经安装完毕"
~~~

