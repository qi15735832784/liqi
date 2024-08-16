# ELK日志分析





## 实验环境

第一台：nginx+filebeat/10.15.200.10

第二台：logstash/10.15.200.11

第三台：els+jdk/10.15.200.12

第四台：kibana/10.15.200.13



### 安装

第一台

~~~shell
#解压nginx-1.6.2.tar.gz
[root@localhost ~]# yum -y install gcc* pcre pcre-devel zlib zlib-devel openssl openssl-devel
[root@localhost ~]# tar -zxf nginx-1.6.2.tar.gz 
[root@localhost ~]# cd nginx-1.6.2/
[root@localhost nginx-1.6.2]# ./configure --prefix=/usr/local/nginx --user=nginx --group=nginx && make && make install
[root@localhost nginx-1.6.2]# useradd -M -s /sbin/nologin nginx
[root@localhost nginx-1.6.2]# ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin/
[root@localhost nginx-1.6.2]# nginx -t
#解压filebeat-6.3.2-linux-x86_64.tar.gz
[root@localhost ~]# tar -zxf filebeat-6.3.2-linux-x86_64.tar.gz
[root@localhost ~]# mv filebeat-6.3.2-linux-x86_64 /usr/local/filebeat
~~~



第二台

~~~shell
#解压logstash-6.3.2.tar.gz
[root@localhost ~]# tar -zxf logstash-6.3.2.tar.gz 
[root@localhost ~]# mv logstash-6.3.2 /usr/local/logstash
~~~



第三台

~~~shell
#解压jdk-8u201-linux-x64.tar.gz 
[root@localhost ~]# tar -zxf jdk-8u201-linux-x64.tar.gz 
[root@localhost ~]# mv jdk1.8.0_201/ /usr/local/java
[root@localhost ~]# rm -rf /usr/bin/java
[root@localhost ~]# vim /etc/profile
#添加最后
export JAVA_HOME=/usr/local/java
export JRE_HOME=/usr/local/java/jre
export CLASSPATH=$JAVA_HOME/lib:$JRE_HOME/lib
export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
[root@localhost ~]# source /etc/profile
#解压elasticsearch-6.3.2.tar.gz 
[root@localhost ~]# tar -zxf elasticsearch-6.3.2.tar.gz 
[root@localhost ~]# mv elasticsearch-6.3.2 /usr/local/es
[root@localhost ~]# useradd es
[root@localhost ~]# chown -R es:es /usr/local/es/
[root@localhost ~]# mkdir -p /es/data /es/log
[root@localhost ~]# chown -R es:es /es/
[root@localhost ~]# vim /etc/security/limits.conf
#最后一行添加
* soft nofile 65535  #用户可以使用文件描述符的数量   
* hard nofile 65536
* soft nproc 2048  #进程可以使用文件描述符的数量 
* hard nproc 4096
* soft memlock ulimited #对进程使用的内存不进行限制
* hard memlock ulimited
[root@localhost ~]# vim /etc/sysctl.conf
#最后添加
vm.max_map_count = 655360 #jvm可以派生的最大进程值
[root@localhost ~]# sysctl -p
[root@localhost ~]# reboot
~~~



第四台

~~~shell
#解压kibana-6.3.2-linux-x86_64.tar.gz 
[root@localhost ~]# tar -zxf kibana-6.3.2-linux-x86_64.tar.gz 
[root@localhost ~]# mv kibana-6.3.2-linux-x86_64 /usr/local/kibana
~~~



### 配置

第一台

~~~shell
[root@localhost ~]# vim /usr/local/filebeat/filebeat.yml
删掉一下几行内容
15 filebeat.inputs:
20 - type: log
25  paths:
26   - /var/log/*.log
添加
14 filebeat:
15   prospectors:
16   - type: log
17     paths: /usr/local/nginx/logs/access.log  #指定nginx的日志文件
18     tags: ["nginx"]   #标签
26 enabled: true   #删除前面的空格，
添加注释
143 #output.elasticsearch:
144 # Array of hosts to connect to.
145 # hosts: ["localhost:9200"]
取消注释
153 output.logstash:
154  # The Logstash hosts
155  hosts: ["10.15.200.11:5044"] #聚合端IP地址（第二台）
~~~

~~~shell
[root@localhost ~]# vim /usr/local/nginx/conf/nginx.conf
取消注释
 21     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
 22                       '$status $body_bytes_sent "$http_referer" '
 23                       '"$http_user_agent" "$http_x_forwarded_for"';
 24 
 25     access_log  logs/access.log  main;
~~~



第二台

~~~shell
[root@localhost ~]# vim /usr/local/logstash/config/logstash.yml
取消注释
64 path.config: /usr/local/logstash/config/*.conf #包连接使用的配置文件
77 config.reload.automatic: true #自动加载手动编写的内容
81 config.reload.interval: 3s #取消注释 自动加载间隔时间
190 http.host: "10.15.200.11" #监听本机IP地址
#编写连接配置文件
[root@localhost ~]# vim /usr/local/logstash/config/nginx-access.conf
input {
  beats {
 port => 5044
   }
}
output {
   elasticsearch {
hosts => "10.15.200.12:9200" #es的IP地址（第三台）
index => "nokafka-nginx"  #索引页（搜索日志时使用）
 }
}
~~~



第三台

重启完成后重新关闭防火墙和沙盒（没有关闭开机自启）

 

生效

[root@localhost ~]# sysctl -p

vm.max_map_count = 655360

[root@localhost ~]# vim /usr/local/es/config/elasticsearch.yml 

