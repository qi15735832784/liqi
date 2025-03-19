# 安装部署zabbix agentd

## 实验环境

### 基于lnmp部署的zabbix进行此次实验

## 实验操作

###  方法一：编译安装

#### 1.下载并解压 Zabbix 源码

~~~shell
cd /usr/local/src/
wget https://cdn.zabbix.com/zabbix/sources/stable/7.2/zabbix-7.2.4.tar.gz
~~~

#### 2.**解压 `zabbix-7.2.4.tar.gz`** 并进入解压后的目录

~~~sehll
tar zxf zabbix-7.2.4.tar.gz
cd zabbix-7.2.4/
~~~

#### 3.安装 `pcre-devel`Zabbix 需要这个库来处理正则表达式

~~~shell
dnf -y install pcre-devel
~~~

#### 4.**手动编译 Zabbix Agent**：

- `--prefix=/usr/local/zabbix`：指定安装路径为 `/usr/local/zabbix/`。
- `--enable-agent`：只编译 `Zabbix Agent`，不包含 `Server` 或 `Proxy` 组件。
- `make && make install`：编译并安装。

~~~shell
./configure prefix=/usr/local/zabbix --enable-agent
make && make install
~~~

#### 5.修改 `zabbix_agentd.conf` 配置

~~~shell
vim /usr/local/zabbix/etc/zabbix_agentd.conf
修改
PidFile=/tmp/zabbix_agentd.pid  #11行取消注释
Server=10.15.200.100         #113行修改为server端IP 
ServerActive=10.15.200.100     #167行修改 
Hostname=node01            #178行修改 

egrep -v '^$|^#' /usr/local/zabbix/etc/zabbix_agentd.conf
~~~

#### 6.创建 `zabbix` 运行用户并修改权限

~~~shell
useradd -r -s /bin/false -M zabbix
chown -R zabbix:zabbix /usr/local/zabbix/
~~~

#### 7.启动 Zabbix Agent 并检查监听端口

~~~shell
/usr/local/zabbix/sbin/zabbix_agentd -c /usr/local/zabbix/etc/zabbix_agentd.conf
~~~

#### 8.**手动启动 Zabbix Agent**，使用刚刚配置的 `zabbix_agentd.conf`

~~~shell
ss -antlp | grep zabbix
~~~





### 方法二：rpm安装

#### 1.安装依赖

~~~shell
dnf -y install pcre-devel
~~~

#### 2.下载 & 安装 `zabbix-agent`

~~~shell
wget https://mirrors.aliyun.com/zabbix/zabbix/7.2/stable/rocky/9/x86_64/zabbix-agent-7.2.4-release1.el9.x86_64.rpm
~~~

#### 3.**使用 RPM 安装 Zabbix Agent**：

- `-i`（install）：安装
- `-v`（verbose）：显示详细信息
- `-h`（hash）：显示进度条

~~~shell
rpm -ivh zabbix-agent-7.2.4-release1.el9.x86_64.rpm
~~~

#### 4.查看 Zabbix Agent 安装的所有文件

~~~shell
rpm -ql zabbix-agent 
~~~

#### 5.修改 `zabbix_agentd.conf` 配置

~~~shell
vim /etc/zabbix/zabbix_agentd.conf
修改
Server=10.15.200.100       #117行修改
ServerActive=10.15.200.100   #171行修改
Hostname=node02          #182行修改
~~~

#### 6.启动 Zabbix Agent 并检查

~~~shell
systemctl start zabbix-agent.service
ss -antlp | grep zabbix
~~~

