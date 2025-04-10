# zabbix服务的应用

## **本章重点：**

l 常用管理工具介绍

l Zabbix企业级分布式监控

l Zabbix企业级应用

l Zabbix企业级高级应用

l Zabbix监控网站实战



Zabbix 是一个基于 WEB 界面的提供分布式系统监视以及网络监视功能的企业级的开源解决方案。zabbix 能监视各种网络参数,保证服务器系统的安全运营;并提供灵活的通知机制以让系统管理员快速定位/解决存在的各种问题。

Zabbix 是由 Alexei Vladishev 创建，目前由 Zabbix SIA 在持续开发和支持。

Zabbix 是一个企业级的分布式开源监控方案。 

Zabbix 是一款能够监控各种网络参数以及服务器健康性和完整性的软件。

Zabbix 使用灵活的通知机制，允许用户为几乎任何事件配置基于邮件的告警。这样可以快速反馈服务器的问题。基于已存储的数据，Zabbix提供了出色的报告和数据可视化功能。这些功能使得Zabbix成为容量规划的理想方案。

Zabbix 支持主动轮询和被动捕获。

Zabbix所有的报告、统计信息和配置参数都可以通过基于Web的前端页面进行访问。基于Web的前端页面可以确保您从任何方面评估您的网络状态和服务器的健康性。

Zabbix是免费的。Zabbix是根据GPL通用公共许可证第2版编写和发行的。这意味着它的源代码都是免费发行的，可供公众任意使用, [商业支持](http://www.zabbix.com/support.php) 由Zabbix公司提供。

## **二、Zabbix 监控介绍**

### **1**、Zabbix 监控架构

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121551849.jpg)

### 2、Zabbix 优点

开源,无软件成本投入

Server 对设备性能要求低

支持设备多,自带多种监控模板

支持分布式集中管理,有自动发现功能,可以实现自动化监控

开放式接口,扩展性强,插件编写容易

当监控的 item 比较多服务器队列比较大时可以采用主动状态,被监控客户端主动 从server 端去下载需要监控的 item 然后取数据上传到 server 端。 这种方式对服务器的负载比较小。

Api 的支持,方便与其他系统结合

### **3**、Zabbix 缺点

需在被监控主机上安装 agent,所有数据都存在数据库里, 产生的数据据很大,瓶颈主要在数据库。

项目批量修改不方便 

社区虽然成熟，但是中文资料相对较少，服务支持有限；

入门容易，能实现基础的监控，但是深层次需求需要非常熟悉Zabbix并进行大量的二次定制开发难度较大

系统级别报警设置相对比较多，如果不筛选的话报警邮件会很多；并且自定义的项目报警需要自己设置，过程比较繁琐；

缺少数据汇总功能，如无法查看一组服务器平均值，需进行二次开发； 

### **4**、Zabbix 监控系统监控对象

 

数据库： MySQL,MariaDB,Oracle,SQL Server agent

应用软件：Nginx,Apache,PHP,Tomcat agent ---------------------------------------------------------------------

 

集群： LVS,Keepalived,HAproxy,RHCS,F5 agent

虚拟化： VMware,KVM,XEN ,docker,k8s agent

操作系统：Linux,Unix,Windows性能参数 agent ---------------------------------------------------------------------

 

硬件： 服务器，存储，网络设备 IPMI

网络： 网络环境（内网环境，外网环境） SNMP ---------------------------------------------------------------------

![img](C:/Users/%E6%9D%8E%E7%90%A6/AppData/Local/Temp/msohtmlclip1/01/clip_image004.jpg)

 

### **5**、Zabbix监控方式

#### 1、被动模式

被动检测：相对于agent而言；agent, server向agent请求获取配置的各监控项相关的数据，agent接收请求、获取数据并响应给server；

 

#### 2、主动模式

主动检测：相对于agent而言；agent(active),agent向server请求与自己相关监控项配置，主动地将server配置的监控项相关的数据发送给server；

主动监控能极大节约监控server 的资源。

 

### **6**、Zabbix 架构

Zabbix由几个主要的软件组件构成，这些组件的功能如下。

##### **![111](https://gitee.com/xiaojinliaqi/img/raw/master/202408121551852.png)

##### 1、Zabbix Server

 

Zabbix server 是 agent 程序报告系统可用性、系统完整性和统计数据的核心组件，是所有配置信息、统计信息和操作数据的核心存储器。

 

##### 2、Zabbix 数据库存储

 

所有配置信息和 Zabbix 收集到的数据都被存储在数据库中。

 

##### 3、Zabbix Web 界面

 

为了从任何地方和任何平台都可以轻松的访问Zabbix, 我们提供基于Web的Zabbix界面。该界面是Zabbix Server的一部分，通常(但不一定)跟Zabbix Server运行在同一台物理机器上。 

如果使用 SQLite,Zabbix Web 界面必须要跟Zabbix Server运行在同一台物理机器上。

 

##### 4、Zabbix Proxy 代理服务器

 

Zabbix proxy 可以替Zabbix Server收集性能和可用性数据。Proxy代理服务器是Zabbix软件可选择部署的一部分；当然，Proxy代理服务器可以帮助单台Zabbix Server分担负载压力。 

 

##### 5、Zabbix Agent 监控代理

 

Zabbix agents监控代理 部署在监控目标上，能够主动监控本地资源和应用程序，并将收集到的数据报告给Zabbix Server。 

 

##### 6、Zabbix 数据流

监控方面，为了创建一个监控项(item)用于采集数据，必须先创建一个主机（host）。  

告警方面，在监控项里创建触发器（trigger），通过触发器（trigger）来触发告警动作（action）。 因此，如果你想收到Server XCPU负载过高的告警，必须满足

###### 1、为Server X创建一个host并关联一个用于对CPU进行监控的监控项（Item）。

###### 2、创建一个Trigger，设置成当CPU负载过高时会触发

###### 3、Trigger被触发，发送告警邮件

虽然看起来有很多步骤，但是使用模板的话操作起来其实很简单，Zabbix 这样的设计使得配置机制非常灵活易用。 

### 7、Zabbix 常用术语的含义

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121551872.jpg)

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121551882.jpg)

 

###### 1、主机 (host)

 

一台你想监控的网络设备，用IP或域名表示

 

###### 2、主机组 (host group) 

 

主机的逻辑组；它包含主机和模板。一个主机组里的主机和模板之间并没有任何直接的关联。通常在给不同用户组的主机分配权限时候使用主机组。

 

###### 3、监控项 (item) 

 

你想要接收的主机的特定数据，一个度量数据。 

 

###### 4、触发器 (trigger) 

 

一个被用于定义问题阈值和“评估”监控项接收到的数据的逻辑表达式 当接收到的数据高于阈值时，触发器从“OK”变成“Problem”状态。当接收到的数据低于阈值时，触发器保留/返回一个“OK”的状态。 

 

###### 5、事件 (event) 

 

单次发生的需要注意的事情，例如触发器状态改变或发现有监控代理自动注册

 

###### 6、异常 (problem) 

 

一个处在“异常”状态的触发器 

 

###### 7、动作 (action) 

 

一个对事件做出反应的预定义的操作。 

一个动作由操作(例如发出通知)和条件(当时操作正在发生)组成

 

###### 8、升级 (escalation) 

 

一个在动作内执行操作的自定义场景; 发送通知/执行远程命令的序列 

（在出现警报或事件时，根据一定规则和条件将警报逐级传递给不同的接收者或执行不同的操作。这可以确保及时的响应和适当的通知。）

###### 9、媒介 (media) 

 

发送告警通知的手段；告警通知的途径 

 

###### 10、通知 (notification) 

 

利用已选择的媒体途径把跟事件相关的信息发送给用户 

 

###### 11、远程命令 (remote command) 

 

一个预定义好的，满足一些条件的情况下，可以在被监控主机上自动执行的命令

 

###### 12、模版 (template) 

 

一组可以被应用到一个或多个主机上的实体（监控项，触发器，图形，聚合图形，应用，LLD，Web场景）的集合 

模版的任务就是加快对主机监控任务的实施；也可以使监控任务的批量修改更简单。模版是直接关联到每台单独的主机上。

 

聚合图形：聚合图形可以在一个页面显示多个数据图表，方便了解多组数据。

###### 13、应用 (application) 

 

一组监控项组成的逻辑分组 

 

###### 14、web 场景 (web scenario) 

 

利用一个或多个HTTP请求来检查网站的可用性

 

###### 15、前端 (frontend) 



Zabbix提供的web界面 

## 实验环境（联网、防火墙、沙盒）

zabbix-server：192.168.100.10 或者（10.15.200.10）

zabbix-agent：192.168.100.11 或者（10.15.200.11）

### zabbix-server

下载网络yum源（如果下载失败尝试将https更改为http）

~~~shell
[root@localhost ~]# rpm -ivh https://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm

[root@localhost ~]# wget -O /etc/yum.repos.d/Centos-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

[root@localhost ~]# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

[root@localhost ~]# yum -y install epel-release

[root@localhost ~]# vim /etc/yum.repos.d/zabbix.repo
gpgcheck=0
gpgcheck=0
 
[root@localhost ~]# yum -y install zabbix-agent zabbix-get zabbix-sender zabbix-server-mysql zabbix-web zabbix-web-mysql
~~~



 安装mariadb

~~~shell
[root@localhost ~]# vim /etc/yum.repos.d/mariadb.repo
[mariadb]
name = MariaDB
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.4/centos7-amd64
gpgkey = https://mirrors.ustc.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck=0

[root@localhost ~]# yum -y install MariaDB-server MariaDB-client
~~~



修改配置文件

~~~shell
[root@localhost ~]# vim /etc/my.cnf.d/server.cnf

13 skip_name_resolve = ON #跳过主机名解析
14 innodb_file_per_table = ON #开启独立表空间
15 innodb_buffer_pool_size = 256M #缓存池大小
16 max_connections = 2000 #最大连接数
17 log-bin = master-log #开启二进制日志
18 innodb_strict_mode = 0 #开启记录大小检查

[root@localhost ~]# systemctl restart mariadb
~~~

 

初始化数据库

~~~shell
[root@localhost ~]# mysql_secure_installation

Enter current password for root (enter for none): #输入当前密码（没有密码直接回车）
Switch to unix_socket authentication [Y/n] Y #是否通过桥接连接
Change the root password? [Y/n] n #是否更改密码
Remove anonymous users? [Y/n] Y #是否要删除匿名用户
Disallow root login remotely? [Y/n] n #是否要禁用root用户远程登陆
Remove test database and access to it? [Y/n] Y #是否移除test库
Reload privilege tables now? [Y/n] Y #是否重新加载权限表
~~~



登陆数据库

~~~shell
[root@localhost ~]# mysql -u root

MariaDB [(none)]> create database zabbix character set 'utf8';
MariaDB [(none)]> grant all on zabbix.* to 'zbxuser'@'192.168.100.%' identified by '123.com';
MariaDB [(none)]> grant all on zabbix.* to 'zbxuser'@'localhost' identified by '123.com';
MariaDB [(none)]> flush privileges;
~~~



将zabbix表导入到zabbix库中

~~~shell
[root@localhost ~]# cd /usr/share/doc/zabbix-server-mysql-4.2.8/
[root@localhost zabbix-server-mysql-4.2.8]# ls
AUTHORS ChangeLog COPYING create.sql.gz NEWS README
[root@localhost zabbix-server-mysql-4.2.8]# gzip -d create.sql.gz 
[root@localhost zabbix-server-mysql-4.2.8]# vim create.sql
第一行添加：USE zabbix;
[root@localhost zabbix-server-mysql-4.2.8]# mysql -uzbxuser -h 192.168.100.10 -p123.com < create.sql
~~~



查看表是否导入成功

~~~shell
MariaDB [(none)]> use zabbix;
MariaDB [zabbix]> show tables;
~~~



修改zabbix的配置文件

~~~shell
[root@localhost zabbix-server-mysql-4.2.8]# cd /etc/zabbix/
[root@localhost zabbix]# ls
web         zabbix_agentd.d
zabbix_agentd.conf zabbix_server.conf
[root@localhost zabbix]# cp zabbix_server.conf zabbix_server.conf.bak
[root@localhost zabbix]# vim zabbix_server.conf
12 ListenPort=10051 #监听端口
19 SourceIP=192.168.100.10 #本机IP
91 DBHost=192.168.100.10 #数据库的IP地址
116 DBUser=zbxuser #管理数据库的用户
124 DBPassword=123.com  #密码
139 DBPort=3306 #数据库端口号
~~~



启动zabbix

~~~shell
[root@localhost zabbix]# systemctl start zabbix-server
[root@localhost zabbix]# netstat -anput | grep 10051
~~~

 

修改httpd和php的配置文件

httpd：

~~~shell
[root@localhost zabbix]# vim /etc/httpd/conf.d/zabbix.conf
20     php_value date.timezone Asia/Shanghai #取消注释  时区：亚洲/上海
~~~

php：

~~~shell
[root@localhost zabbix]# vim /etc/php.ini
878 date.timezone = Asia/Shanghai 
~~~



启动httpd

~~~shell
[root@localhost zabbix]# systemctl start httpd
[root@localhost zabbix]# systemctl enable httpd
~~~



 访问图形化界面

~~~shell
[root@localhost zabbix]# firefox 192.168.100.10/zabbix
~~~

![](https://gitee.com/xiaojinliaqi/img/raw/master/202408121545434.png)

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121546426.jpg)

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121546425.jpg)

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121546428.jpg)

 ![image-20240813103300716](https://gitee.com/xiaojinliaqi/img/raw/master/202408131033782.png)

![image-20240813103317231](https://gitee.com/xiaojinliaqi/img/raw/master/202408131033271.png)

![image-20240813103335300](https://gitee.com/xiaojinliaqi/img/raw/master/202408131033333.png)

![image-20240813103348022](https://gitee.com/xiaojinliaqi/img/raw/master/202408131033061.png)

 

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121546402.jpg)

 

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121546437.jpg)

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121546487.jpg)

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121546560.jpg)

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202408121546591.jpg)

 

###  zabbix-agent

 安装网络yum源

~~~shell
[root@localhost ~]# rpm -ivh **https**://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm

[root@localhost ~]# wget -O /etc/yum.repos.d/Centos-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

[root@localhost ~]# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

[root@localhost ~]# yum -y install epel-release

[root@localhost ~]# vim /etc/yum.repos.d/zabbix.repo
gpgcheck=0
gpgcheck=0
~~~



安装组件

~~~shell
[root@localhost ~]# yum -y install zabbix-agent zabbix-sender
~~~



修改配置文件

~~~shell
[root@localhost ~]# cd /etc/zabbix/
[root@localhost zabbix]# ls
zabbix_agentd.conf zabbix_agentd.d
#防止手残做个备份
[root@localhost zabbix]# cp zabbix_agentd.conf zabbix_agentd.conf.bak
[root@localhost zabbix]# vim zabbix_agentd.conf
98 Server=192.168.100.10 #服务端的ip地址
106 ListenPort=10050 #监听端口
114 ListenIP=0.0.0.0 #监听任意地址
123 StartAgents=3 #agent连接server的时间
139 ServerActive=192.168.100.10 #主动连接server的IP地址
150 Hostname=node1 #server端识别agent的名称
~~~



修改主机名

~~~shell
[root@localhost zabbix]# hostnamectl set-hostname node1
[root@localhost zabbix]# bash
~~~



启动agent

~~~shell
[root@node1 zabbix]# systemctl start zabbix-agent
[root@node1 zabbix]# netstat -anput | grep 10050
tcp    0 0 0.0.0.0:10050  0.0.0.0:* LISTEN   61501/zabbix_agentd
~~~



### zabbix-server：（写解析地址）

~~~shell
[root@localhost zabbix]# vim /etc/hosts
192.168.100.11 node1
~~~



创建主机和群组

![image-20240813205129212](https://gitee.com/xiaojinliaqi/img/raw/master/202408132051255.png)

![image-20240813205302047](https://gitee.com/xiaojinliaqi/img/raw/master/202408132053087.png)

 

创建主机

![image-20240813205425261](https://gitee.com/xiaojinliaqi/img/raw/master/202408132054304.png)

 ![image-20240813205622918](https://gitee.com/xiaojinliaqi/img/raw/master/202408132056966.png)

 

添加监控项

![image-20240813205727004](https://gitee.com/xiaojinliaqi/img/raw/master/202408132057054.png)

![image-20240813205745379](https://gitee.com/xiaojinliaqi/img/raw/master/202408132057410.png)

![image-20240813205753577](https://gitee.com/xiaojinliaqi/img/raw/master/202408132057613.png)

![image-20240813205804130](https://gitee.com/xiaojinliaqi/img/raw/master/202408132058169.png)

![image-20240813205854176](https://gitee.com/xiaojinliaqi/img/raw/master/202408132058214.png)

![image-20240813210004839](https://gitee.com/xiaojinliaqi/img/raw/master/202408132100905.png)

添加监控项（带参数）

创建应用集

![image-20240813210049053](https://gitee.com/xiaojinliaqi/img/raw/master/202408132100095.png)

![image-20240813210109740](https://gitee.com/xiaojinliaqi/img/raw/master/202408132101783.png)

![image-20240813210124000](https://gitee.com/xiaojinliaqi/img/raw/master/202408132101049.png)

![image-20240813210147696](https://gitee.com/xiaojinliaqi/img/raw/master/202408132101733.png)

![image-20240813210437822](https://gitee.com/xiaojinliaqi/img/raw/master/202408132104864.png)

![image-20240813210508422](https://gitee.com/xiaojinliaqi/img/raw/master/202408132105469.png)

![image-20240813210533136](https://gitee.com/xiaojinliaqi/img/raw/master/202408132105179.png)

![image-20240813210656924](https://gitee.com/xiaojinliaqi/img/raw/master/202408132106971.png)

通过命令获取值（只能获取命令执行这一刻的数值）

~~~shell
[root@localhost ~]# zabbix_get -s 10.15.200.11 -p 10050 -k "net.if.in[ens32,packets]"
22917
~~~



自动发现

再准备一台agent

IP地址：192.168.100.12（10.15.200.12）

主机名：node2

服务端修改hosts文件添加node2的主机名和IP地址

![image-20240813210947163](https://gitee.com/xiaojinliaqi/img/raw/master/202408132109204.png)

![image-20240813211006904](https://gitee.com/xiaojinliaqi/img/raw/master/202408132110945.png)

![image-20240813211027255](https://gitee.com/xiaojinliaqi/img/raw/master/202408132110295.png)

![image-20240813211042929](https://gitee.com/xiaojinliaqi/img/raw/master/202408132110980.png)

![image-20240813211100396](https://gitee.com/xiaojinliaqi/img/raw/master/202408132111453.png)



自动发现动作

![image-20240813211148857](https://gitee.com/xiaojinliaqi/img/raw/master/202408132111893.png)

![image-20240813211211093](https://gitee.com/xiaojinliaqi/img/raw/master/202408132112137.png)

使用相同的方式添加其他三个条件

![image-20240813211231088](https://gitee.com/xiaojinliaqi/img/raw/master/202408132112129.png)

![image-20240813211246802](https://gitee.com/xiaojinliaqi/img/raw/master/202408132112854.png)

![image-20240813211258774](https://gitee.com/xiaojinliaqi/img/raw/master/202408132112821.png)

![image-20240813211316075](https://gitee.com/xiaojinliaqi/img/raw/master/202408132113118.png)

![image-20240813211329841](https://gitee.com/xiaojinliaqi/img/raw/master/202408132113879.png)

![image-20240813211349692](https://gitee.com/xiaojinliaqi/img/raw/master/202408132113748.png)

![image-20240813211607582](https://gitee.com/xiaojinliaqi/img/raw/master/202408132116627.png)



自动注册

![image-20240814084836358](https://gitee.com/xiaojinliaqi/img/raw/master/202408140848427.png)

![image-20240814085108352](https://gitee.com/xiaojinliaqi/img/raw/master/202408140851406.png)

![image-20240814085150821](https://gitee.com/xiaojinliaqi/img/raw/master/202408140851871.png)

![image-20240814085640819](https://gitee.com/xiaojinliaqi/img/raw/master/202408140856867.png)



配置邮件报警

zabbix绑定邮箱获取授权码 vrfjrmigimcaebci

![image-20240814094912160](https://gitee.com/xiaojinliaqi/img/raw/master/202408140949216.png)



~~~shell
[root@localhost ~]# yum -y install mailx
[root@localhost ~]# vim /etc/mail.rc
 70 set sendcharsets=iso-8859-1,utf-8   #字符集
 71 set from=2590220540@qq.com   #自己邮箱
 72 set smtp=smtp.qq.com   #使用qq邮箱
 73 set smtp-auth-user=2590220540@qq.com  #自己邮箱
 74 set smtp-auth-password=ujkkxearyckleaaj   #自己的授权码
 75 set smtp-auth=login   #使用身份验证的方式进行登陆
#测试发邮件
[root@localhost ~]# echo "guqinyuewoaini" |  mail -s "zabbix" 2590220540@qq.com
~~~

编写发邮件发邮件的脚本

~~~shell
[root@localhost zabbix]# cd /usr/lib/zabbix/alertscripts/
[root@localhost alertscripts]# vim mailx.sh
#!/bin/bash
#send mail
messages=echo $3 | tr '\r\n' 'n'
subject=echo $2 | tr '\r\n' 'n'
echo "${messages}" | mail -s "${subject}" $1 >> /tmp/mailx.log 2>&1

[root@localhost alertscripts]# touch /tmp/mailx.log
[root@localhost alertscripts]# chown -R zabbix:zabbix /tmp/mailx.log 
[root@localhost alertscripts]# chmod +x mailx.sh 
[root@localhost alertscripts]# chown -R zabbix:zabbix /usr/lib/zabbix/
~~~

![image-20240814102905087](https://gitee.com/xiaojinliaqi/img/raw/master/202408141029160.png)

{ALERT.SENDTO}

{ALERT.SUBJECT}  

{ALERT.MESSAGE} 

![image-20240814103213826](https://gitee.com/xiaojinliaqi/img/raw/master/202408141032885.png)

![image-20240814103606413](https://gitee.com/xiaojinliaqi/img/raw/master/202408141036499.png)



发送邮件需要绑定用户

管理 → 用户 → Admin → 报警媒介 → 添加 → 收件人 → 添加 → 更新

![image-20240814104605877](https://gitee.com/xiaojinliaqi/img/raw/master/202408141046944.png)

![image-20240814104747960](https://gitee.com/xiaojinliaqi/img/raw/master/202408141047030.png)

![image-20240814104819138](https://gitee.com/xiaojinliaqi/img/raw/master/202408141048196.png)

自定义键值

~~~shell
agent1：
[root@node1 ~]# vim /etc/zabbix/check_httpd.sh
#!/bin/bash
a=`systemctl status httpd`
if [ "$?" = 0 ];then
        echo '0' 
else
        echo '1'
fi

安装httpd
[root@node1 yum.repos.d]# yum -y install httpd
测试脚本
[root@node1 ~]# chmod +x /etc/zabbix/check_httpd.sh 
http未启动返回1
[root@node1 ~]# /etc/zabbix/check_httpd.sh 
1
httpd启动返回0
[root@node1 ~]# systemctl start httpd
[root@node1 ~]# /etc/zabbix/check_httpd.sh 
0

修改agent配置文件，自定义键值
[root@node1 ~]# vim /etc/zabbix/zabbix_agentd.conf
287 UnsafeUserParameters=1  #开启自定义·键值
296 UserParameter=check_httpd,sh /etc/zabbix/check_httpd.sh
              自定义键值名称  调用键值时执行该脚本

重启agent服务
[root@node1 ~]# systemctl restart zabbix-agent
[root@node1 ~]# netstat -anput | grep 10050
tcp        00 0.0.0.0:10050   0.0.0.0:* LISTEN      68472/zabbix_agentd

zabbix-server：
验证
agent1再httpd启动的状态下查看自定义键值返回的数值
[root@localhost ~]# zabbix_get -s 192.168.100.11 -k check_httpd
0

将agent1的httpd服务停止后，测试该键值是否可以正常检测
[root@localhost ~]# zabbix_get -s 192.168.100.11 -k check_httpd
1
~~~

触发器

server

![image-20240815173325934](https://gitee.com/xiaojinliaqi/img/raw/master/202408151733107.png)

![image-20240815173404154](https://gitee.com/xiaojinliaqi/img/raw/master/202408151734199.png)

![image-20240815173414617](https://gitee.com/xiaojinliaqi/img/raw/master/202408151734665.png)

添加触发器

![image-20240815173451123](https://gitee.com/xiaojinliaqi/img/raw/master/202408151734163.png)

![image-20240815173511429](https://gitee.com/xiaojinliaqi/img/raw/master/202408151735474.png)

![image-20240815173530030](https://gitee.com/xiaojinliaqi/img/raw/master/202408151735085.png)

![image-20240815173548849](https://gitee.com/xiaojinliaqi/img/raw/master/202408151735908.png)

![image-20240815173604823](https://gitee.com/xiaojinliaqi/img/raw/master/202408151736878.png)

添加动作

![image-20240815173706089](https://gitee.com/xiaojinliaqi/img/raw/master/202408151737135.png)

![image-20240815173730591](https://gitee.com/xiaojinliaqi/img/raw/master/202408151737651.png)

![image-20240815173752452](https://gitee.com/xiaojinliaqi/img/raw/master/202408151737509.png)

![image-20240815173808192](https://gitee.com/xiaojinliaqi/img/raw/master/202408151738245.png)

![image-20240815173822860](https://gitee.com/xiaojinliaqi/img/raw/master/202408151738907.png)

![image-20240815173845539](https://gitee.com/xiaojinliaqi/img/raw/master/202408151738596.png)

![image-20240815173903449](https://gitee.com/xiaojinliaqi/img/raw/master/202408151739503.png)

验证：

agent1：

停止apache

[root@node1 ~]# systemctl stop httpd

实验效果（两种效果均为正确）

1、远程命令执行成功（node1上httpd启动成功），此时不会发送邮件（问题会变为已解决）

2、远程命令执行失败，执行第二个动作（发送邮件）

 

server

![image-20240815173940055](https://gitee.com/xiaojinliaqi/img/raw/master/202408151739107.png)

![image-20240815173956397](https://gitee.com/xiaojinliaqi/img/raw/master/202408151739448.png)

![image-20240815174019925](https://gitee.com/xiaojinliaqi/img/raw/master/202408151740983.png)



页面篡改

agent1

修改网站页面

~~~shell
[root@node1 ~]# echo zabbix > /var/www/html/index.html
[root@node1 ~]# curl localhost
zabbix
~~~



编写监控页面的脚本文件

~~~shell
[root@node1 ~]# vim /tmp/auto_montitor_httpd.sh
\#!/bin/bash
aa=`curl -s http://192.168.100.11 | grep -c "zabbix"`
echo $aa
~~~



授权

~~~shell
[root@node1 ~]# chmod +x /tmp/auto_montitor_httpd.sh
~~~



自定义键值

~~~shell
[root@node1 ~]# vim /etc/zabbix/zabbix_agentd.conf
297 UserParameter=check_httpd_word,sh /tmp/auto_montitor_httpd.sh
~~~



~~~shell
[root@node1 ~]# systemctl restart zabbix-agent
[root@node1 ~]# netstat -anput | grep 10050
tcp    0   0 0.0.0.0:10050      0.0.0.0:*        LISTEN   70915/zabbix_agentd
~~~



server端检查键值是否可以使用

~~~shell
[root@localhost ~]# zabbix_get -s 192.168.100.11 -k check_httpd_word
1
~~~



配置监控项

![image-20240815174234192](https://gitee.com/xiaojinliaqi/img/raw/master/202408151742259.png)

![image-20240815174310173](https://gitee.com/xiaojinliaqi/img/raw/master/202408151743220.png)

![image-20240815174337493](https://gitee.com/xiaojinliaqi/img/raw/master/202408151743554.png)

![image-20240815174357330](https://gitee.com/xiaojinliaqi/img/raw/master/202408151743385.png)

![image-20240815174411669](https://gitee.com/xiaojinliaqi/img/raw/master/202408151744731.png)

![image-20240815174436683](https://gitee.com/xiaojinliaqi/img/raw/master/202408151744739.png)

![image-20240815174454490](https://gitee.com/xiaojinliaqi/img/raw/master/202408151744542.png)

![image-20240815174516848](https://gitee.com/xiaojinliaqi/img/raw/master/202408151745904.png)

![image-20240815174526072](https://gitee.com/xiaojinliaqi/img/raw/master/202408151745123.png)

![image-20240815174536464](https://gitee.com/xiaojinliaqi/img/raw/master/202408151745526.png)

![image-20240815174546506](https://gitee.com/xiaojinliaqi/img/raw/master/202408151745557.png)

验证

agent1

![image-20240815174833054](https://gitee.com/xiaojinliaqi/img/raw/master/202408151748110.png)

agent1：

~~~shell
[root@node1 ~]# yum -y install mariadb*
~~~



zabbix系统中有监控mysql的模板，可以直接使用

~~~shell
[root@node1 ~]# vim /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf
17 UserParameter=mysql.ping,HOME=/var/lib/zabbix mysqladmin ping 2> /dev/null | grep -c alive
~~~



~~~shell
[root@node1 ~]# systemctl restart zabbix-agent

[root@node1 ~]# netstat -anput | grep zabbix_agentd

tcp    0   0 0.0.0.0:10050  0.0.0.0:* LISTEN  71987/zabbix_agentd
~~~



启动mariadb

~~~shell
[root@node1 ~]# systemctl start mariadb
~~~



zabbix测试键值是否可以使用（0未启动 1启动）

~~~shell
[root@localhost ~]# zabbix_get -s 192.168.100.11 -k mysql.ping
1
~~~

![image-20240815174922006](https://gitee.com/xiaojinliaqi/img/raw/master/202408151749054.png)

 ![image-20240815174936447](https://gitee.com/xiaojinliaqi/img/raw/master/202408151749507.png)



监控项：

 ![image-20240815175007733](https://gitee.com/xiaojinliaqi/img/raw/master/202408151750790.png)

创建动作

![image-20240815175026753](https://gitee.com/xiaojinliaqi/img/raw/master/202408151750799.png)

‘![image-20240815175101951](https://gitee.com/xiaojinliaqi/img/raw/master/202408151751014.png)

![image-20240815175116063](https://gitee.com/xiaojinliaqi/img/raw/master/202408151751130.png)

![image-20240815175130543](https://gitee.com/xiaojinliaqi/img/raw/master/202408151751611.png)



agent：

将mariadb停止验证

~~~shell
[root@node1 ~]# systemctl stop mariadb
~~~



server

![image-20240815175223854](https://gitee.com/xiaojinliaqi/img/raw/master/202408151752925.png)

 
