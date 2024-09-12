# Git

开发使用组合命令比较多 

因为如果更改完源代码 需要重新编译重新打包  生产环境中

## 理论

版本控制式一种记录一个或若个文件内容变化，以便将来查阅特定版本修订情况的系统（记录代码文件的变化），采用版本控制系统（version control system--->VCS）你就可以将某个文件回溯到之前的状态，甚看，至将整个项目都回退到过去某个时间点的状态，你可以比较文件的变化细节，查出最后是谁修改了哪个地方，从而找出导致怪异问题出现的原因，又是谁在何时报告了某个功能缺陷等等，使用版本控制系统通常还意味着，就算你乱来一气把整个项目中的文件改的改删的删，你也照样可以轻松恢复到原先的样子，但额外增加的工作量却微乎其微

Git是一个分布式版本控制系统：记录项目代码

## 版本控制系统存在的方式(VCS version control system)：

1.简单的VCS 单个数据库记录代码的内容变化

2.集中式的版本控制系统CVCS centralized version control system  svn

## git特点：

1.直接记录快照，而非差异比较（不用比较差异）

2.Git一般只增加数据（拉取、上传代码）

3.Git保证代码完整性（git在每一次提交上传的时候，会比较远程仓库的信息校验和本地仓库的信息校验是否一样，一样的话继续上传，不一样停止上传，任何事情不可以绕开git操作）





## 实验环境

一台节点 10.15.200.10

## 安装git

~~~shell
[root@localhost ~]# yum -y install git
[root@localhost ~]# mkdir /test
[root@localhost ~]# cd /test/
[root@localhost test]# ls -a
~~~

## 初始化版本库

~~~shell
[root@localhost test]# git init
初始化空的 Git 版本库于 /test/.git/
[root@localhost test]# ls -a
.  ..  .git
~~~

## 常用的逻辑操作

### 1.将代码添加到暂存区   add

### 2.将暂存区的代码提交到本地仓库   commiit

### 3.将本地仓库的内容上传到远程仓库   push

## 编写代码

~~~shell
[root@localhost test]# vim test.py
#!/usr/bin/python
print("hello")
[root@localhost test]# python test.py 
~~~

## 将代码添加到暂存区

~~~shell
[root@localhost test]# git add test.py
[root@localhost test]# git status 
# 位于分支 master
#
# 初始提交
#
# 要提交的变更：
#   （使用 "git rm --cached <file>..." 撤出暂存区）
#
#       新文件：    test.py
~~~

在第一次将代码提交到本地仓库之前，需要设置用户名和邮箱（用于追踪提交的用户），之后默认会使用该用户，直到工作目录发生变化会再次进行设置

~~~shell
[root@localhost test]# git config --global user.name "aa"
[root@localhost test]# git config --global user.email aa@163.com
~~~

## 将暂存区的代码提交到本地仓库

~~~shell
[root@localhost test]# git commit -m first""
[master（根提交） 9223298] first
 1 file changed, 2 insertions(+)
 create mode 100644 test.py
~~~

~~~shell
[root@localhost test]# git log 
commit 9223298f4b2fd516bdd49cb0e96142955cefae19
Author: aa <aa@163.com>
Date:   Tue Aug 20 17:36:21 2024 +0800

    first
~~~

## 代码回滚

### 1、代码在暂存区中进行回滚（未提交到本地仓库）

修改代码

~~~shell
[root@localhost test]# vim test.py
#!/usr/bin/python
print("hello")
print("haha")
~~~

根据提示撤出暂存区

~~~shell
[root@localhost test]# git status
# 位于分支 master
# 要提交的变更：
#  （使用 "git reset HEAD <file>..." 撤出暂存区）**
#
#   修改：   test.py
#
[root@localhost test]# git reset HEAD test.py
~~~

撤出暂存区后文件内容没有变化

~~~shell
[root@localhost test]# cat test.py 
#!/usr/bin/python
print("hello")
print("haha")
~~~

再次查看状态信息

~~~~shell
[root@localhost test]# git status 
# 位于分支 master
# 尚未暂存以备提交的变更：
#   （使用 "git add <file>..." 更新要提交的内容）
#   （使用 "git checkout -- <file>..." 丢弃工作区的改动）
#
#       修改：      test.py
#
修改尚未加入提交（使用 "git add" 和/或 "git commit -a"）
~~~~

根据提示丢弃工作区的改动

~~~shell
[root@localhost test]# git checkout -- test.py
~~~

代码文件回滚成功

~~~shell
[root@localhost test]# cat test.py 
#!/usr/bin/python
print("hello")
~~~

### 2、代码已经提交到本地仓库进行回滚

~~~shell
[root@localhost test]# vim test.py 
#!/usr/bin/python
print("hello")
print("hehe")
~~~

将代码提交到本地仓库

~~~shell
[root@localhost test]# git add test.py
[root@localhost test]# git commit -m "second"
[master 6a5d92f] second
 1 file changed, 1 insertion(+)
[root@localhost test]# git status 
# 位于分支 master
无文件要提交，干净的工作区
~~~

查看两次提交记录

~~~shell
[root@localhost test]# git log
commit 6a5d92f8997556468df039713a41adae066eae6a
Author: aa <aa@163.com>
Date:   Tue Aug 20 17:52:07 2024 +0800

    second

commit 9223298f4b2fd516bdd49cb0e96142955cefae19
Author: aa <aa@163.com>
Date:   Tue Aug 20 17:36:21 2024 +0800

    first
~~~

## 回滚

复制要回滚的提交id

~~~shell
[root@localhost test]# git reset --hard 9223298f4b2fd516bdd49cb0e96142955cefae19
HEAD 现在位于 9223298 first
~~~

查看代码文件内容

~~~shell
[root@localhost test]# cat test.py 
#!/usr/bin/python
print("hello")
[root@localhost test]# git log 
commit 9223298f4b2fd516bdd49cb0e96142955cefae19
Author: aa <aa@163.com>
Date:   Tue Aug 20 17:36:21 2024 +0800

    first
~~~



## 分支

主干：git是以时间为主线对版本进行管理的，这条时间线就是git的主干，主干上每个节点就是一次提交，即为一个版本，在主干上用户可以定义多个指针，指向不同的节点git默认会创建一个叫做master的指针，默认情况下用户操作都是在master上进行的，但是用户可以对操作的指针进行切换，用户每提交一次，就会形成一个新的节点，当前指针就会像前移动一次

### 查看分支（*号代表当前所在的分支）

~~~shell
[root@localhost test]# git branch 
* master
~~~

### 创建分支

~~~shell
[root@localhost test]# git branch aa 
[root@localhost test]# git branch 
  aa
* master
~~~

### 切换分支

~~~shell
[root@localhost test]# git checkout aa
切换到分支 'aa'
[root@localhost test]# git branch 
* aa
  master
~~~

修改代码文件

~~~shell
[root@localhost test]# cat test.py 
#!/usr/bin/python
print("hello")
print("heihei")
~~~

提交到本地仓库

~~~shell
[root@localhost test]# git add test.py
[root@localhost test]# git commit -m "aa"
[aa 2175f38] aa
 1 file changed, 1 insertion(+)
[root@localhost test]# cat test.py 
#!/usr/bin/python
print("hello")
print("heihei")
~~~

### 切换到master指针

~~~shell
[root@localhost test]# git checkout master 
切换到分支 'master'
~~~

查看文件内容，此时可以看到分支对代码文件的修改不会对其他分支产生影响（文件内容没有变化）

~~~shell
[root@localhost test]# cat test.py 
#!/usr/bin/python
print("hello")
~~~

将分支代码合并到主干

~~~shell
[root@localhost test]# git merge aa
更新 9223298..2175f38
Fast-forward
 test.py | 1 +
 1 file changed, 1 insertion(+)
~~~

合并完成后可以看到主干代码文件内容更新

~~~shell
[root@localhost test]# cat test.py 
#!/usr/bin/python
print("hello")
print("heihei")
~~~

# github远程仓库（www.github.com）注册账号

![image-20240912104959587](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102908.png)



创建仓库

![image-20240912105127239](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102523.png)

![image-20240912105153105](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102412.png)

![image-20240912105212352](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102213.png)

本地仓库与远程仓库进行连接（需要用到密钥对）

生成密钥对

~~~shell
[root@localhost ~]# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:drB+C4uAZi5xAI+kZ36RvGLhCWqX0cFCZmmVyJrONaM root@localhost.localdomain
The key's randomart image is:
+---[RSA 2048]----+
|  o+=..          |
|..o* +           |
|+o+.o.. .        |
|=o==+.   o       |
|+Boo=o  S .      |
|oEB+o  o .       |
|.+=o.   o .      |
|.+   . . + .     |
| ..   . . .      |
+----[SHA256]-----+
[root@localhost ~]# ls /root/.ssh/
id_rsa  id_rsa.pub
[root@localhost ~]# cat /root/.ssh/id_rsa.pub 
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqbu55C0eJvuiLZ2lUyztp5DBzphWWgYmQW4JRCeWipRyJSkBGmMEeJBrdvpQt/NSJA7LERPzwpC6uLlEkfIFh5+K/tlxRix8fdVLQah7laoBPgp+oGSffgNBQOHFtwl9pP8Ya1AC6rdNZ0Ro4zSOJLm4bC6jBg9z9ztDKMHNTYI8UVF9oRe8OGlvQ+RszEJEVg5CZGKLbMxt8w06xHCkWixOdihgQWp6jON111czqkOGTVUU3DEOnXYK8DujLZ+gisgQEq4juVyLCQTxPf8FJd8XeB3VoRQS+De5i1rXC9SWuk23TJ4g+8pzl3b5Zm3ldiJ5JzR79aoo97UyaVI/B root@localhost.localdomain
~~~

将公钥文件上传到github上

![image-20240912105544412](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102656.png)

![image-20240912105604595](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102481.png)

![image-20240912105631578](https://gitee.com/xiaojinliaqi/img/raw/master/202409121056632.png)

![image-20240912105702405](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102965.png)

测试本地仓库是否可以连接远程仓库

~~~shell
[root@localhost test]# ssh -T git@github.com
Hi qi15735832784! You've successfully authenticated, but GitHub does not provide shell access.
~~~

向远程仓库推送数据

![image-20240912105845874](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102090.png)

![image-20240912105908801](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102345.png)

![image-20240912105921220](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102124.png)

![image-20240912105932548](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102446.png)

![image-20240912105945180](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102727.png)

![image-20240912105954052](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102870.png)

![image-20240912110003847](https://gitee.com/xiaojinliaqi/img/raw/master/202409121102808.png)

~~~shell
[root@localhost test]# git remote add origin git@github.com:qi15735832784/docker_image_pusher
[root@localhost test]# git remote add origin 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@github.com:qi15735832784/docker_image_pusher
fatal: 远程 origin 已经存在。
[root@localhost test]# git remote remove origin 
[root@localhost test]# git remote add origin git@github.com:qi15735832784/docker_image_pusher
[root@localhost test]# git push -u origin master
Counting objects: 6, done.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (6/6), 449 bytes | 0 bytes/s, done.
Total 6 (delta 0), reused 0 (delta 0)
remote: 
remote: Create a pull request for 'master' on GitHub by visiting:
remote:      https://github.com/qi15735832784/docker_image_pusher/pull/new/master
remote: 
remote: To git@github.com:qi15735832784/docker_image_pusher
 * [new branch]      master -> master
分支 master 设置为跟踪来自 origin 的远程分支 master。
~~~

克隆（下载）

复制仓库地址

![image-20240912110413825](https://gitee.com/xiaojinliaqi/img/raw/master/202409121104886.png)

克隆

~~~shell
[root@localhost test]# git clone git@github.com:guojianyonsir/aaa.git
正克隆到 'aaa'...
remote: Enumerating objects: 6, done.
remote: Counting objects: 100% (6/6), done.
remote: Compressing objects: 100% (2/2), done.
接收对象中: 100% (6/6), done.
remote: Total 6 (delta 0), reused 6 (delta 0), pack-reused 0 (from 0)
~~~

查看当前目录是否有克隆的代码

~~~shell
[root@localhost test]# ls
aaa  test.py
[root@localhost test]# ls aaa/
test.py

~~~

# **Gitlab**

理论

Gitlab作为一个开源项目开始帮助团队在团建开发上进行合作，通过以业界领先的步伐交付新的功能为整个软件开发和操作生命周期提供了一个单独的应用平台。Gitlab提供了管理、计划、创建、验证、打包、发布、配置、监视和保护应用程序所需的一切。Gitlab是一个基于git实现的在线代码仓库托管软件，一般用于企业、学校等内部网络搭建git私服。Gitlab是一个提供代码托管、提交审核和问题跟踪的代码管理平台。

代码托管平台：

1. SVN

2. github（全世界都在使用，人家创建好的，注册就可以使用，企业用的话不安全）

3. gitlab(自己公司自己使用，企业自己可以创建)

 

git、gitlab、github的区别

git：是一种基于命令的版本控制系统，没有可视化界面

gitlab：是一个基于git实现的在线代码仓库软件，提供web可视化全命令操作，管理界面，通常用于企业团对内部协作开发

github：是一个基于git实现的在线代码托管仓库，亦提供可视化管理界面，同时免费账户和提供付费账户，提供开放和私有的仓库，大部分的开源项目都选择github作为代码托管仓库（开源：开放源代码）

 

gitlab服务的组合部分

nginx：nginx是一个高性能的开源http和反向代理服务器，也可以作为静态web服务器，它通常用于http请求代理到后端应用服务器，提供静态文件服务

gitlab-shell：是一个用于处理git命令，提供git操作的功能

gitlab-workhorse：是一个轻量级的反向代理服务器用于处理一些大型的http请求，例如文件的下载上传

logrotate：是一个用于管理日志文件的工具，它允许你根据特定的规则轮转，压缩，删除日志文件，以便于管理和维护日志数据

postgresql：是一个强大的开源关系型数据库管理系统，它提供可靠的数据持久化，高级数据完整性和丰富的功能，被广泛用于各种类型的应用程序

redis：reids是一个高性能开源内存缓存数据库，它支持多种数据结构，用于缓存常用的数据，提高应用的响应速度

sidekkiq：用于后台执行队列任务，它基于消息队列的概念，允许你异步执行耗时的任务，从而提高应用程序的性能和响应能力

unicorn：是用ruby编写的一个http服务器，通常用于托管ruby on rails 应用程序，他是一个多进程服务器，可以处理多进程服务器，可以处理并发的http请求



常用命令

启动组件nginx

~~~shell
gitlab-ctl start nginx
~~~

开启、关闭、重启gitlab

~~~shell
gitlab-ctl start | stop | restart
~~~

查看gitlab的日志

~~~shell
gitlab-ctl tail
~~~

重新编译

~~~shell
gitlab-ctl reconfigure
~~~

进入gitlab的shell

~~~shell
gitlab-rails console
~~~



# 实验环境

一台节点 10.15.200.10

## 安装依赖，本地安装

~~~shell
[root@localhost ~]# yum -y install cronie openssh-clients openssh-server policycoreutils-python
[root@localhost ~]# yum -y localinstall gitlab-ce-12.3.0-ce.0.el7.x86_64.rpm 
~~~

## 修改配置文件

~~~shell
[root@localhost ~]# vim /etc/gitlab/gitlab.rb 
13 external_url 'http://10.15.200.10'   #本机IP
~~~

## 重新编译

~~~shell
[root@localhost ~]# gitlab-ctl reconfigure
~~~

## 修改用户密码

~~~shell
[root@localhost ~]# gitlab-rails console
--------------------------------------------------------------------------------
 GitLab:       12.3.0 (7099ecf77cb)
 GitLab Shell: 10.0.0
 PostgreSQL:   10.9
--------------------------------------------------------------------------------
Loading production environment (Rails 5.2.3)
irb(main):001:0> user = User.where(id:1).first
=> #<User id:1 @root>
irb(main):002:0> user.password='!@#qweASD69'
=> "!@#qweASD69"
irb(main):003:0> user.save!
Enqueued ActionMailer::DeliveryJob (Job ID: 68ecb499-b966-4e79-8bb4-bec03f625845) to Sidekiq(mailers) with arguments: "DeviseMailer", "password_change", "deliver_now", #<GlobalID:0x00007fc884520e50 @uri=#<URI::GID gid://gitlab/User/1>>
=> true
~~~

访问页面

~~~shell
firefox 10.15.200.10
~~~

![image-20240822101303610](https://gitee.com/xiaojinliaqi/img/raw/master/202408221013820.png)

![image-20240822102205980](https://gitee.com/xiaojinliaqi/img/raw/master/202408221022033.png)

邮件报警

163授权码：ZTAVDJYHNHROKMUH

修改配置文件

~~~shell
[root@localhost ~]# vim /etc/gitlab/gitlab.rb 
53 gitlab_rails['gitlab_email_from'] = 'lq212308@163.com'   #自己邮箱
559-567 取消注释并修改
 559 gitlab_rails['smtp_enable'] = true
 560 gitlab_rails['smtp_address'] = "smtp.163.com"
 561 gitlab_rails['smtp_port'] = 25
 562 gitlab_rails['smtp_user_name'] = "lq212308@163.com"
 563 gitlab_rails['smtp_password'] = "ZTAVDJYHNHROKMUH"
 564 gitlab_rails['smtp_domain'] = "163.com"
 565 gitlab_rails['smtp_authentication'] = "login"
 566 gitlab_rails['smtp_enable_starttls_auto'] = false
 567 gitlab_rails['smtp_tls'] = false
~~~

重新编译生效配置

~~~shell
[root@localhost ~]# gitlab-ctl reconfigure
~~~



进入shell进行测试

```shell
[root@localhost ~]# gitlab-rails console
irb(main):001:0> 
Notify.test_email('gjy18534447826@163.com','heihei','ooooooooo').deliver_now
```

备份和恢复

备份gitlab上的仓库

```shell
[root@localhost ~]# gitlab-rake gitlab:backup:create
Creating backup archive: **1724298317_2024_08_22_12.3.0**_gitlab_backup.tar ... done
```

恢复

将队列服务和http服务停止

```shell
[root@localhost ~]# gitlab-ctl stop sidekiq
ok: down: sidekiq: 1s, normally up
[root@localhost ~]# gitlab-ctl stop unicorn
ok: down: unicorn: 0s, normally up
```



```shell
[root@localhost ~]# gitlab-rake gitlab:backup:restore BACKUP=1724298317_2024_08_22_12.3.0
```

两次yes

启动两个服务

```shell
[root@localhost ~]# gitlab-ctl start unicorn
ok: run: unicorn: (pid 80380) 0s
[root@localhost ~]# gitlab-ctl start sidekiq
ok: run: sidekiq: (pid 80413) 0s
```

图形化界面

[root@localhost ~]# firefox 10.15.200.10

![image-20240912111246887](https://gitee.com/xiaojinliaqi/img/raw/master/202409121112940.png)

创建用户

![image-20240912111425270](https://gitee.com/xiaojinliaqi/img/raw/master/202409121114310.png)

![image-20240912111439861](https://gitee.com/xiaojinliaqi/img/raw/master/202409121114911.png)

 ![image-20240912111452984](https://gitee.com/xiaojinliaqi/img/raw/master/202409121114032.png)

![image-20240912111504793](https://gitee.com/xiaojinliaqi/img/raw/master/202409121115837.png)



 

 

 

 

 

 

 

 

 

 
