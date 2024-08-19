# Maven相关内容

## java项目

源代码

编译

测试

打包：jar，war

## Maven相关内容

### 1.功能 管理java项目的

1）maven模型的Java项目对源代码、单元测试代码、资源、jar包等有规范的目录规划

2）解决项目间的依赖关系、版本不一致、版本冲突问题

3）合理的jar包管理机制

### 2.应用场景----从运维角度理解

1）原来项目中的jar包必须手动复制、粘贴到WEB-INF/lib项目下而借助maven，可以将jar包仅仅保存在仓库中，有需要使用的工程只需要引用这个文件，并不需要重复复制到工程中

2）原来的项目中所需要的jar包都提前下载好的，而maven在联网状态下会自动下载所需要的jar包，首先在本地仓库中找，找不到就在网上进行下载

3）原来的项目中一个jar包所依赖的其他jar包必须手动导进来，而maven会自动将被以来的jar包导进来



jar

Jar包是来实现某一个功能，每一个功能都有对应的jar包

War包web程序打包，直接就能部署的，war包就是一个项目

 

目录结构 举例：/tmp/kgcapp

目录     pom.xml                   说明

/tmp/kgcapp          项目的根目录，存在pom.xml和所有的子目录

/tmp/kgcapp/src/main/resources  项目的资源，比如说property文件，springmvc.xml

/tmp/kgcapp/src/test/java      项目的测试类。比如说junit代码

/tmp/kgcapp/src/test/resources   测试用例，用的找资源

/tmp/kgcapp/src/main/webapp    web应用文件按目录，比如存放web.xml、本地图片、jsp视图页面

/tmp/kgcapp/target         打包输出目录，比如打包好的jar包或war包

/tmp/kgcapp/target/classes     编译输出目录，用于保存输出的class文件

/tmp/kgcapp/target/test-classe 测试编译输出目录

## 关于仓库（本地仓库——远程仓库）

### 1 本地仓库（优先级最高）

Maven会将工程依赖的构件（jar包）从远程下载到本机一个项目下管理，每个电脑默认的仓库是在“用户家目录下的.m2/repository”

### 2 远程仓库

#### 1）第三方仓库  (gitlab github)

第三方仓库又称为内部中心仓库，也称为私服

一般是由公司内部构件自己设立的，只为本公司内部共享使用，它既可以作为公司内部构件协作和存档，也可以作为公用类库镜缓存，减少在外部访问和下载的频率（使用了私服就减少了对中央仓库的访问）

#### 2）中央仓库

Maven内置了远程公用仓库

Maven官方仓库

http://repol.maven.org.maven2 这个公共仓库是由maven自己维护，里面有 大量的常用类库，并包含了世界上大部分流行的开源项目构件，目前是以java为主，工程需要的jar如果本地仓库没有，默认从中央仓库下载。

maven的使用需要java的源代码  所以需要我们下载所需的源代码

做maven的实验  首先需要有一个java项目  所以需要自己下载一个java的项目

创建一个目录 因为有时候在root的家目录下 有可能下载不成功





## 实验环境

一台节点

解压jdk-8u201-linux-x64.tar.gz 

~~~shell
[root@localhost ~]# tar -zxf jdk-8u201-linux-x64.tar.gz 
[root@localhost ~]# mv jdk1.8.0_201/ /usr/local/java
[root@localhost ~]# rm -rf /usr/bin/java
[root@localhost ~]# vim /etc/profile
在会后添加
export JAVA_HOME=/usr/local/java
export JRE_HOME=/usr/local/java/jre
export CLASSPATH=$JAVA_HOME/lib:$JRE_HOME/lib
export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin:/usr/local/maven/bin
~~~



解压apache-maven-3.6.0-bin.tar.gz 

~~~shell
[root@localhost ~]# tar -zxf apache-maven-3.6.0-bin.tar.gz 
[root@localhost ~]# mv apache-maven-3.6.0 /usr/local/maven
[root@localhost ~]# source /etc/profile
[root@localhost ~]# java -version
[root@localhost ~]# mvn -v
[root@localhost ~]# cd /usr/local/maven/
~~~



下载工程类的项目模板

~~~shell
[root@localhost ~]# mkdir test
[root@localhost ~]# cd test/
[root@localhost test]# mvn archetype:generate -DgroupId=com.kgc.kgcapp -DartifactId=kgcapp -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
#使用 Maven 的 archetype:generate 插件创建一个新的 Java 项目。各个参数的含义如下：
-DgroupId=com.kgc.kgcapp：指定项目的组 ID，通常是一个唯一的反向域名，例如 com.kgc.kgcapp。
-DartifactId=kgcapp：指定项目的构件 ID，通常是项目的名称，例如 kgcapp。
-DarchetypeArtifactId=maven-archetype-quickstart：指定使用的模板类型，这里是 maven-archetype-quickstart，这是一个简单的 Maven 项目模板，适用于快速创建 Java 应用程序。
-DinteractiveMode=false：表示在生成项目时不使用交互模式，所有参数将根据命令行参数自动设置，不需要用户进一步输入。
~~~

编译

~~~shell
[root@localhost test]# cd kgcapp/
[root@localhost kgcapp]# mvn compile
编译完后会有target目录
[root@localhost kgcapp]# ls
pom.xml  src  target
~~~

测试

~~~shell
[root@localhost kgcapp]# mvn test
~~~

打包

~~~shell
[root@localhost kgcapp]# mvn package
[root@localhost kgcapp]# ls target/
classes                  maven-archiver  surefire-reports
kgcapp-1.0-SNAPSHOT.jar  maven-status    test-classes
~~~

将jar包上传到本地仓库

~~~shell
[root@localhost kgcapp]# mvn install
~~~

清除

~~~shell
[root@localhost kgcapp]# mvn clean
~~~



组合命令

清空并打包

~~~shell
[root@localhost kgcapp]# mvn clean package
~~~



配置镜像仓库，提高下载依赖的速度

~~~shell
[root@localhost kgcapp]# vim /usr/local/maven/conf/settings.xml
添加：（在mirrors标签内）
159     <mirror>
160        <id>aliyun</id>   #镜像的唯一标识符
161        <mirrorOf>central</mirrorOf>   #指定这个镜像用于 Maven 的中央仓库
162        <name>aliyun-maven</name>   #镜像的名称
163        <url>http://maven.aliyun.com/nexus/content/groups/public</url>   #镜像的实际 URL 地址
164     </mirror>
[root@localhost kgcapp]# mvn clean package   #执行 Maven 的构建生命周期
。clean：删除以前构建产生的所有文件，确保一个干净的构建环境。
。package：编译代码并将其打包成 JAR 文件（或其他类型的包），并将其放置在 target 目录中。
~~~

