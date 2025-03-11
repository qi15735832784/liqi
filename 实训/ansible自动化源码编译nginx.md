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

