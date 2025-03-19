# ansible自动化源码编译nginx

## 1.配置相互免密

~~~shell
ssh-keygen
ssh-copy-id root@10.15.200.134
~~~

![image-20250311184653200](https://gitee.com/xiaojinliaqi/img/raw/master/202503111846284.png)

## 2.配置仓库

~~~shell
cd /etc/yum.repos.d/
vim ansible.repo
[ansible]
neme=ansible
baseurl=file:///root/ansible
gpgcheck=0
enabled=1
~~~

![image-20250311184736883](https://gitee.com/xiaojinliaqi/img/raw/master/202503111847932.png)

## 3.拷贝软件包

~~~shell
tar -zxf ansible.el9.tgz
yum makecache
~~~

![image-20250311184802154](https://gitee.com/xiaojinliaqi/img/raw/master/202503111848195.png)

## 4.安装ansible

~~~shell
yum -yq install ansible-core
~~~

![image-20250311184823424](https://gitee.com/xiaojinliaqi/img/raw/master/202503111848480.png)

## 5.修改配置文件

~~~shell
vim /etc/ansible/ansible.cfg
[defaults]
inventory = /etc/ansible/inventory
remote_user = root
host_key_checking = False
~~~

![image-20250311184848925](https://gitee.com/xiaojinliaqi/img/raw/master/202503111848975.png)

## 6.编辑配置清单

~~~shell
vim /etc/ansible/inventory 
添加
host1
~~~

## ![image-20250311184921721](https://gitee.com/xiaojinliaqi/img/raw/master/202503111849765.png)7.编辑域名

~~~shell
vim /etc/hosts
添加
10.15.200.134 host1
~~~

![image-20250311184945703](https://gitee.com/xiaojinliaqi/img/raw/master/202503111849741.png)

## 8.自动将一个Tab设置为两个空格

~~~shell
echo "autocmd FileType yaml setlocal ai ts=2 sw=2 et" > $HOME/.vimrc
~~~

## 9.配置剧本

~~~yml
vim nginx.yml 
- name: 安装nginx
  hosts: host1
  tasks:
#    - name: 关闭防火墙沙盒
#      shell: systemctl stop firewalld && setenforce 0
    - name: 安装依赖
      shell: yum -y install pcre-devel openssl-devel zlib-devel
    - name: 创建用户和组
      shell: groupadd -r www && useradd -g www -M -s /bin/false www
    - name: 拷贝软件包
      shell: scp 10.15.200.100:/root/nginx-1.26.3.tar.gz /root/
    - name: 编译nginx
      shell: tar -zxvf /root/nginx-1.26.3.tar.gz && cd /root/nginx-1.26.3/ && ./configure --prefix=/usr/local/nginx --group=www --user=www  --sbin-path=/usr/sbin  && make && make install && nginx
~~~

![image-20250311185027644](https://gitee.com/xiaojinliaqi/img/raw/master/202503111850691.png)

## 10.执行剧本

~~~shell
ansible-playbook nginx.yml
~~~

![image-20250311185101398](https://gitee.com/xiaojinliaqi/img/raw/master/202503111851457.png)

## 11.验证

~~~shell
curl 10.15.200.134
~~~

![image-20250311185124431](https://gitee.com/xiaojinliaqi/img/raw/master/202503111851486.png)



# playbook部署lnmp平台+zabbix

## 实验环境

两台rocky9的主机【IP分别为：`控制端10.15.200.100`，`被控制端10.15.200.134`】

## 先配置被控制端

~~~shell
[root@localhost ~]# systemctl stop firewalld
[root@localhost ~]# setenforce 0
[root@localhost ~]# hostnamectl set-hostname zabbix
[root@localhost ~]# bash
~~~

## 控制端操作如下

## 1.配置相互免密(两边都需要配置)

~~~shell
ssh-keygen
ssh-copy-id root@10.15.200.134
~~~

![image-20250311184653200](https://gitee.com/xiaojinliaqi/img/raw/master/202503111846284.png)

## 2.配置仓库

~~~shell
cd /etc/yum.repos.d/
vim ansible.repo
[ansible]
neme=ansible
baseurl=file:///root/ansible
gpgcheck=0
enabled=1
~~~

![image-20250311184736883](https://gitee.com/xiaojinliaqi/img/raw/master/202503111847932.png)

## 3.拷贝软件包

~~~shell
tar -zxf ansible.el9.tgz
yum makecache
~~~

![image-20250311184802154](https://gitee.com/xiaojinliaqi/img/raw/master/202503111848195.png)

## 4.安装ansible

~~~shell
yum -yq install ansible-core
~~~

![image-20250311184823424](https://gitee.com/xiaojinliaqi/img/raw/master/202503111848480.png)

## 5.修改配置文件

~~~shell
vim /etc/ansible/ansible.cfg
[defaults]
inventory = /etc/ansible/inventory
remote_user = root
host_key_checking = False
~~~

![image-20250311184848925](https://gitee.com/xiaojinliaqi/img/raw/master/202503111848975.png)

## 6.编辑配置清单

~~~shell
vim /etc/ansible/inventory 
添加
zabbix
~~~

![image-20250319124256652](https://gitee.com/xiaojinliaqi/img/raw/master/202503191242793.png)

## 7.编辑域名

~~~shell
vim /etc/hosts
添加
10.15.200.134 host1
~~~

![image-20250319124324261](https://gitee.com/xiaojinliaqi/img/raw/master/202503191243308.png)

## 8.配置playbook剧本

~~~shell
mkdir /my
~~~

### 01.依赖剧本

~~~shell
vim yilai.yaml
- hosts: zabbix
  tasks:
    - name: 
      shell: dnf config-manager --set-enabled crb && dnf clean all  && dnf install -y epel-release

    - name: 安装依赖包 
      dnf:
        name:
          - gcc
          - make
          - libxml2-devel
          - sqlite-devel
          - bzip2-devel
          - curl-devel
          - libpng-devel
          - libjpeg-devel
          - freetype-devel
          - openssl-devel
          - libxslt-devel
          - systemd-devel
          - autoconf
          - libtool
          - re2c
          - gd
          - gd-devel
          - zlib
          - freetype
          - freetype-devel
          - libjpeg
          - libavif-devel
          - wget
          - git
          - cmake
          - gcc-c++
          - pcre-devel
          - zlib-devel
          - gd-devel
          - perl-ExtUtils-Embed
          - libmaxminddb-devel
          - gperftools-devel
          - libatomic_ops-devel
          - perl-devel
          - curl-devel
          - libicu-devel
          - oniguruma
          - oniguruma-devel
          - libzip
          - libzip-devel
          - bzip2-devel
          - readline-devel
          - libedit-devel
          - libffi-devel
          - libyaml
          - libyaml-devel
          - sqlite-devel
          - net-snmp-devel
          - libevent-devel
          - openldap-devel
          - gettext-devel
          - libssh2-devel
          - unixODBC
          - OpenIPMI-devel
          - langpacks-zh_CN
          - glibc-langpack-zh.x86_64
        state: present
~~~

### 02.mysql剧本

~~~shell
vim mysql.yaml
---
- hosts: zabbix
  tasks:

    - name: 创建组
      group: 
        name: mysql 
        system: yes

    - name: 创建用户
      user: 
        name: mysql 
        system: yes 
        group: mysql 
        shell: /bin/false 
        create_home: no

    - name: 传输mysql包
      copy: 
        src: /my/mysql-8.0.41-linux-glibc2.17-x86_64-minimal.tar.xz 
        dest: /usr/local
        force: yes

    - name: 解包
      unarchive: 
        dest: /usr/local 
        src: /usr/local/mysql-8.0.41-linux-glibc2.17-x86_64-minimal.tar.xz 
        remote_src: yes

    - name: 重命名
      shell: mv /usr/local/mysql-8.0.41-linux-glibc2.17-x86_64-minimal /usr/local/mysql 

    - name: 创建mysql数据目录
      file: 
        path: /usr/local/mysql/data 
        state: directory

    - name: 给mysql目录权限
      file: 
        path: /usr/local/mysql 
        owner: mysql 
        group: mysql 
        recurse: yes

    - name: 创建mysql配置文件 
      copy:
        dest: /etc/my.cnf
        content: |
          [mysqld]
          basedir=/usr/local/mysql
          datadir=/usr/local/mysql/data
          pid-file=/usr/local/mysql/data/mysqld.pid
          log-error=/usr/local/mysql/data/mysql.err
          socket=/tmp/mysql.sock
          user=mysql
          [client]
          socket=/tmp/mysql.sock

    - name: 初始化 MySQL 数据目录
      shell: /usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data

    - name: 修改启动时使用文件
      shell: ln -s /usr/lib64/libncurses.so.6.2 /usr/lib64/libncurses.so.5 && ln -s /usr/lib64/libtinfo.so.6.2 /usr/lib64/libtinfo.so.5


    - name: 加入系统服务
      copy:
        dest: /usr/lib/systemd/system/mysqld.service
        content: |
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

    - name: 重载服务
      systemd:
        daemon_reload: yes

    - name: 启动
      systemd:
        name: mysqld
        state: started
        enabled: yes

    - name: 等待10s
      pause:
        seconds: 10

    - name: 获取mysql临时密码
      shell: awk '/temporary password/{print $NF}' /usr/local/mysql/data/mysql.err
      register: mysql_temp_password

    - name: 使用临时密码登录mysql修改root密码
      shell: /usr/local/mysql/bin/mysql -uroot -p'{{ mysql_temp_password.stdout }}' --connect-expired-password -e "alter user 'root'@'localhost' identified by '123';"
~~~

### 03.nginx剧本

~~~shell
vim nginx.yaml
- hosts: zabbix
  tasks:
   - name: 创建组
     group: 
        name: www 
        system: yes

   - name: 创建用户
     user: 
       name: www 
       system: yes 
       group: www 
       shell: /bin/false 
       create_home: no

   - name: 传输压缩包
     copy: 
       src: /my/nginx-1.26.3.tar.gz 
       dest: /usr/local/ 

   - name: 解压
     unarchive: 
       dest: /usr/local/ 
       src: /usr/local/nginx-1.26.3.tar.gz 
       remote_src: yes

   - name: 配置编译安装
     shell: chdir=/usr/local/nginx-1.26.3 ./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module   --with-http_v2_module  --with-http_addition_module  --with-http_sub_module  --with-http_dav_module   --with-http_flv_module  --with-http_mp4_module  --with-http_random_index_module  --with-http_stub_status_module  && make && make install

   - name: 加入系统服务
     copy:
       dest: /usr/lib/systemd/system/nginx.service
       content: | 
         [Unit]
         Description=OpenNginx server daemon  
         After=network.target

         [Service]
         Type=forking
         PIDFile=/usr/local/nginx/logs/nginx.pid
         ExecStart=/usr/local/nginx/sbin/nginx
         ExecReload=/usr/local/nginx/sbin/nginx -s reload
         ExecStop=/bin/kill -s QUIT $MAINPID
         PrivateTmp=true

         [Install]
         WantedBy=multi-user.target


   - name: 重新加载 systemd 配置
     systemd:
      daemon_reload: yes
   
   - name: 启动
     systemd:
       name: nginx
       state: started
       enabled: yes
~~~

### 04.php剧本

~~~shell
vim php.yaml
- hosts: zabbix
  tasks:
    - name: 传输php包
      copy:
        src: /my/php-8.1.31.tar.gz
        dest: /usr/local
        force: yes

    - name: 解包
      unarchive: 
        dest: /usr/local 
        src: /usr/local/php-8.1.31.tar.gz
        remote_src: yes

    - name: 配置编译安装
      shell: ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-pdo-mysql=mysqlnd --with-openssl --with-curl --with-zlib --with-freetype --with-jpeg --with-xsl --with-mysqli --enable-mbstring --enable-opcache --enable-bcmath --enable-intl --with-pear --enable-sockets --enable-gd --with-jpeg --with-avif --with-webp --with-xpm && make && make install
      args:
        chdir: /usr/local/php-8.1.31

    - name: 复制php配置文件
      copy:
        src: "{{ item.src }}"
        dest: "{{ item.dest }}"
        remote_src: yes
      with_items:
        - { src: "/usr/local/php-8.1.31/php.ini-production", dest: "/usr/local/php/etc/php.ini" }
        - { src: "/usr/local/php/etc/php-fpm.conf.default", dest: "/usr/local/php/etc/php-fpm.conf" }
        - { src: "/usr/local/php/etc/php-fpm.d/www.conf.default", dest: "/usr/local/php/etc/php-fpm.d/www.conf" }

    - name: 加入系统服务
      copy:
        dest: /etc/systemd/system/php-fpm.service
        content: |
          [Unit]
          Description=The PHP FastCGI Process Manager
          After=network.target

          [Service]
          Type=simple
          PIDFile=/usr/local/php/var/run/php-fpm.pid
          ExecStart=/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf
          ExecReload=/bin/kill -USR2 $MAINPID

          [Install]
          WantedBy=multi-user.target

    - name: 重新加载 systemd 配置
      systemd:
        daemon_reload: yes

    - name: 启动 php-fpm 服务
      systemd:
        name: php-fpm
        state: started
        enabled: yes
~~~

### 05.zabbix剧本

~~~shell
vim zabbix.yaml
---
- hosts: zabbix
  tasks:
    - name:
      shell: ln -s /usr/local/mysql/bin/* /usr/sbin/

    - name: 创建组
      group: 
        name: zabbix
        system: yes

    - name: 创建用户
      user:
        name: zabbix
        system: yes
        group: zabbix
        shell: /bin/false
        create_home: no

    - name: 创建 Zabbix 数据库
      shell: |
          /usr/local/mysql/bin/mysql -uroot -p123 -e "
          CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;
          CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '123';
          GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
          FLUSH PRIVILEGES;"
      args:
        executable: /bin/bash

    - name:  传输zabbix包
      copy: 
        src: /my/zabbix-7.2.4.tar.gz
        dest: /usr/local
        force: yes

    - name: 解包
      unarchive:
        dest: /usr/local
        src: /usr/local/zabbix-7.2.4.tar.gz
        remote_src: yes

    - name: 配置编译安装
      shell: cd /usr/local/zabbix-7.2.4 && ./configure --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 --with-openssl --with-ldap --with-ssh2 --with-libevent --with-libpcre --with-libxslt --with-iconv --with-openipmi && make && make install

    - name: 导入 schema.sql
      shell: |
        mysql -uroot -p123  zabbix < /usr/local/zabbix-7.2.4/database/mysql/schema.sql

    - name: 导入 images.sql
      shell: |
        mysql -uroot -p123  zabbix < /usr/local/zabbix-7.2.4/database/mysql/images.sql

    - name: 导入 data.sql
      shell: |
        mysql -uroot -p123  zabbix < /usr/local/zabbix-7.2.4/database/mysql/data.sql

    - name: 设置 DBPassword
      lineinfile:
        path: /usr/local/etc/zabbix_server.conf
        regexp: '^#?DBPassword='
        line: 'DBPassword=123'

    - name: 创建 Zabbix 网页目录
      file:
        path: /usr/local/nginx/html/zabbix
        state: directory

    - name: 导入zabbix网页文件
      copy:
        src: /usr/local/zabbix-7.2.4/ui/
        dest: /usr/local/nginx/html/zabbix/
        remote_src: yes

    - name: 设置 Zabbix 安装目录的所有者
      file:
        path: /usr/local/zabbix
        owner: zabbix
        group: zabbix
        recurse: yes

    - name: 为 Zabbix 安装目录添加可执行权限
      file:
        path: /usr/local/zabbix
        mode: "a+X"
        recurse: yes

    - name: 覆盖nginx.conf文件
      copy:
        dest: /usr/local/nginx/conf/nginx.conf
        content: |
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
                      index  index.html index.htm;
                  }
                  error_page   500 502 503 504  /50x.html;
                  location = /50x.html {
                      root   html;
                  }
                  location ~ \.php$ {
                      fastcgi_pass   127.0.0.1:9000;
                      fastcgi_index  index.php;
                      fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
                      include        fastcgi_params;
                  }
              }
            }


    - name: 创建启动文件
      shell: ln -s /usr/local/mysql/lib/libmysqlclient.so.21 /usr/lib64/libmysqlclient.so.21
    
    - name: 设置 post_max_size
      lineinfile:
        path: /usr/local/php/etc/php.ini
        regexp: '^;?post_max_size ='
        line: 'post_max_size = 16M'

    - name: 设置 max_execution_time
      lineinfile:
        path: /usr/local/php/etc/php.ini
        regexp: '^;?max_execution_time ='
        line: 'max_execution_time = 300'

    - name: 设置 max_input_time
      lineinfile:
        path: /usr/local/php/etc/php.ini
        regexp: '^;?max_input_time ='
        line: 'max_input_time = 300'


    - name: 加入系统服务
      copy:
        dest: /usr/lib/systemd/system/zabbix-server.service
        content: |
          [Unit]
          Description=Zabbix Server
          After=network.target mysql.service

          [Service]
          Type=forking
          ExecStart=/usr/local/sbin/zabbix_server -c /usr/local/etc/zabbix_server.conf
          ExecReload=/bin/kill -HUP $MAINPID
          User=zabbix
          Group=zabbix
          Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          Environment="LD_LIBRARY_PATH=/usr/local/etc:/usr/local/lib:/usr/lib:/lib"

          [Install]
          WantedBy=multi-user.target

    - name: 重新加载 systemd 配置
      systemd:
        daemon_reload: yes

    - name: 启动zabbix
      systemd:
        name: zabbix-server
        state: started
        enabled: yes

    - name: 重启php服务
      systemd:
        name: php-fpm
        state: restarted


    - name: 重启nginx服务
      systemd:
        name: nginx
        state: restarted

    - name:  传输登录包
      copy:
        src: /my/zabbix.conf.php
        dest: /usr/local/nginx/html/zabbix/conf/
        force: yes
~~~

### 06.任务剧本

~~~shell
vim mian.yaml 
- import_playbook: yilai.yaml
- import_playbook: mysql.yaml
- import_playbook: nginx.yaml
- import_playbook: php.yaml
- import_playbook: zabbix.yaml
~~~

### 07.php页面

~~~shell
vim zabbix.conf.php
<?php
// Zabbix GUI configuration file.

$DB['TYPE']                     = 'MYSQL';
$DB['SERVER']                   = 'localhost';
$DB['PORT']                     = '0';
$DB['DATABASE']                 = 'zabbix';
$DB['USER']                     = 'zabbix';
$DB['PASSWORD']                 = '123';

// Schema name. Used for PostgreSQL.
$DB['SCHEMA']                   = '';

// Used for TLS connection.
$DB['ENCRYPTION']               = false;
$DB['KEY_FILE']                 = '';
$DB['CERT_FILE']                = '';
$DB['CA_FILE']                  = '';
$DB['VERIFY_HOST']              = false;
$DB['CIPHER_LIST']              = '';

// Vault configuration. Used if database credentials are stored in Vault secrets manager.
$DB['VAULT']                    = '';
$DB['VAULT_URL']                = '';
$DB['VAULT_PREFIX']             = '';
$DB['VAULT_DB_PATH']            = '';
$DB['VAULT_TOKEN']              = '';
$DB['VAULT_CERT_FILE']          = '';
$DB['VAULT_KEY_FILE']           = '';
// Uncomment to bypass local caching of credentials.
// $DB['VAULT_CACHE']           = true;

// Uncomment and set to desired values to override Zabbix hostname/IP and port.
// $ZBX_SERVER                  = '';
// $ZBX_SERVER_PORT             = '';

$ZBX_SERVER_NAME                = 'zabbix';

$IMAGE_FORMAT_DEFAULT   = IMAGE_FORMAT_PNG;

// Uncomment this block only if you are using Elasticsearch.
// Elasticsearch url (can be string if same url is used for all types).
//$HISTORY['url'] = [
//      'uint' => 'http://localhost:9200',
//      'text' => 'http://localhost:9200'
//];
// Value types stored in Elasticsearch.
//$HISTORY['types'] = ['uint', 'text'];

// Used for SAML authentication.
// Uncomment to override the default paths to SP private key, SP and IdP X.509 certificates, and to set extra settings.
//$SSO['SP_KEY']                        = 'conf/certs/sp.key';
//$SSO['SP_CERT']                       = 'conf/certs/sp.crt';
//$SSO['IDP_CERT']              = 'conf/certs/idp.crt';
//$SSO['SETTINGS']              = [];

// If set to false, support for HTTP authentication will be disabled.
// $ALLOW_HTTP_AUTH = true;
~~~



## 9.下载压缩包，将压缩包放在`/root/my`目录

~~~shell
cd /my
wget https://nginx.org/download/nginx-1.26.3.tar.gz
wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.41-linux-glibc2.17-x86_64-minimal.tar.xz
wget https://www.php.net/distributions/php-8.1.31.tar.gz
wget https://cdn.zabbix.com/zabbix/sources/stable/7.2/zabbix-7.2.4.tar.gz
~~~

![image-20250319125858974](https://gitee.com/xiaojinliaqi/img/raw/master/202503191258083.png)

## 10.开始自动部署

~~~shell
cd /my
ansible-playbook mian.yaml 
~~~

![image-20250319130246669](https://gitee.com/xiaojinliaqi/img/raw/master/202503191302935.png)

## 11.访问`http://10.15.200.134/zabbix/index.php`

![image-20250319130440932](https://gitee.com/xiaojinliaqi/img/raw/master/202503191304082.png)
