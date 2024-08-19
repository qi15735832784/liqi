# ELK日志分析

### ELK：日志分析

E：es（elasticsearch）

L：logstash

K：kibana

### 日志分析系统的作用：

1、信息检索---快速找到bug---修复、优化

2、服务的诊断--- >负载情况和运行状态

3、数据的分析

### 日志分析系统的组件

1、采集端（agent） ：采集日志源数据，对数据进行封装并发送给聚合端

2、聚合端（collector）：搜集来自多个采集端的日志数据，并且按照一定的规则进行数据的处理

3、存储端storage：负责存储来自聚合端的数据

![image-20240819115459924](https://gitee.com/xiaojinliaqi/img/raw/master/202408191155023.png)

Data collection：数据的收集

data processing：数据的处理

storage：数据的存储

visualize：数据的可视化

redis：消息队列（当数据量不高时，可以省略）

logstash：数据的处理，使用数据存储更方便，建立索引

elastic search ：直接对数据的索引进行存储·

kibana： 从es里面拿去数据进行显示，有内置的一些分析工具，将数据进行分析，筛选





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
154  # The Logstash hosts  #（此处的#号不取消）
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
64 path.config: /usr/local/logstash/config/*.conf  #包含连接使用的配置文件
77 config.reload.automatic: true  #自动加载手动编写的内容
81 config.reload.interval: 3s  #自动加载间隔时间
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

~~~shell
重启完成后重新关闭防火墙和沙盒（没有关闭开机自启）
[root@localhost ~]# systemctl stop firewalld
[root@localhost ~]# systemctl disable firewalld
[root@localhost ~]# setenforce 0
生效
[root@localhost ~]# sysctl -p
vm.max_map_count = 655360 #jvm可以派生的最大进程值

修改配置文件
[root@localhost ~]# vim /usr/local/es/config/elasticsearch.yml
17 cluster.name: my-application  #集群名称
23 node.name: node-1  #节点名称
24 node.master: true  #当前节点作为主节点
25 node.data: true    #数据存放再当前节点
35 path.data: /es/data  #数据目录
39 path.logs: /es/log  #日志目录
45 bootstrap.memory_lock: false  #不对使用的内存进行限制
46 bootstrap.system_call_filter: false  #不对使用的系统资源进行限制
58 network.host: 10.15.200.12  #本机IP
62 http.port: 9200  #监听端口号
75 discovery.zen.minimum_master_nodes: 1  #当前集群中有几个节点
~~~



第四台

~~~shell
[root@localhost ~]# vim /usr/local/kibana/config/kibana.yml
2 server.port: 5601  #监听端口
7 server.host: "10.15.200.13"  #本机IP
28 elasticsearch.url: "http://10.15.200.12:9200"  #指定es的IP地址（第三台）
~~~



### 启动

第一台：

~~~shell
[root@localhost ~]# nginx
[root@localhost ~]# /usr/local/filebeat/filebeat -c /usr/local/filebeat/filebeat.yml
~~~



第二台

 ~~~shell
 [root@localhost ~]# /usr/local/logstash/bin/logstash -f /usr/local/logstash/config/nginx-access.conf
 ~~~



第三台

~~~shell
切换到普通用户启动es
[root@localhost ~]# su es
[es@localhost root]$ /usr/local/es/bin/elasticsearch
~~~

 

第四台

~~~shell
[root@localhost ~]# /usr/local/kibana/bin/kibana
~~~



在第一台访问

~~~shell
对nginx多次访问（产生访问日志）
[root@localhost ~]# curl 192.168.100.10
访问第四台的图形化界面
[root@localhost ~]# firefox 192.168.100.13:5601
~~~

![image-20240816121226472](https://gitee.com/xiaojinliaqi/img/raw/master/202408161212566.png)

![image-20240816121639788](https://gitee.com/xiaojinliaqi/img/raw/master/202408161216850.png)

![image-20240816121741004](https://gitee.com/xiaojinliaqi/img/raw/master/202408161217060.png)

![image-20240816121900012](https://gitee.com/xiaojinliaqi/img/raw/master/202408161219070.png)

![image-20240816121940445](https://gitee.com/xiaojinliaqi/img/raw/master/202408161219505.png)

![image-20240816122041391](https://gitee.com/xiaojinliaqi/img/raw/master/202408161220450.png)

多次访问nginx刷新页面查看访问量是否发生变化

![image-20240816122305990](https://gitee.com/xiaojinliaqi/img/raw/master/202408161223040.png)

















