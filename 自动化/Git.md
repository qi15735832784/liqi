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



