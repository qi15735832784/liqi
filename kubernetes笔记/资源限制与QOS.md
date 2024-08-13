# 资源限制与QOS

![image-20240805171945652](https://gitee.com/xiaojinliaqi/img/raw/master/202408051719866.png)



超卖：limit 可以，requests 不可以，cpu可以，memory不可以
requests 小于 limits = Burstable
requests 等于 limits = Guaranteed
requests 和 limits  没有设置 = BestEffort

###### LimitRange:

避免用户配置每个容器，已 namespace 为单位
1.指定能给容器配置的每种资源的最大和最小限制
2.没有设置的资源限制的容器，设置默认限制





~~~shell
vim pod.yaml
###
apiVersion: v1   #Kubernetes API 的版本，这里使用的是 v1 版本
kind: Pod   #定义对象类型，这里是 Pod，表示要创建一个 Pod
metadata:   #元数据部分，包含 Pod 的名称和其他信息
  name: req-box-1   #Pod 的名称，这里为 req-box-1
spec:   #Pod 的规格，定义了 Pod 的内容和行为
  containers:   #Pod 中运行的容器列表
  - name: main   #容器的名称，这里为 main
    image: busybox:1.36   #使用的容器镜像，这里是 busybox:1.36，表示使用 BusyBox 工具箱的特定版本
    imagePullPolicy: IfNotPresent   #容器镜像拉取策略，这里设置为 IfNotPresent，表示只有在本地不存在时才从远程仓库拉取
    command: ["sleep","1d"]   #容器启动时执行的命令，这里是 sleep 1d，表示容器将休眠 1 天（24 小时）
    resources:   #容器的资源需求配置
      requests:   #定义容器所需的资源量
        cpu: 200m   #CPU 请求量，设置为 200m，表示 0.2 个 CPU 核心
        memory: 10Mi   #内存请求量，设置为 10Mi，表示 10 Mebibytes（MiB）的内存（大约 10.5 MB）

~~~

命名空间内的所有容器总共请求和限制的 CPU 和内存资源不会超过设定的配额

~~~shell
vim quota.yaml 
###
apiVersion: v1   #指定使用的 API 版本，这里是 v1
kind: ResourceQuota   #定义资源类型，这里是资源配额
metadata:
  name: cpu-and-mem   #资源配额的名称，这里命名为 `cpu-and-mem`
spec:
  hard:   #指定资源配额的硬限制
    requests.cpu: 400m   #在该命名空间中，所有容器请求的 CPU 总量不能超过 400 毫核（即 0.4 个 CPU 核）
    requests.memory: 200Mi   #在该命名空间中，所有容器请求的内存总量不能超过 200 MiB
    limits.cpu: 600m   #在该命名空间中，所有容器限制的 CPU 总量不能超过 600 毫核（即 0.6 个 CPU 核）
    limits.memory: 500Mi   #在该命名空间中，所有容器限制的内存总量不能超过 500 MiB

~~~







## helm 的三大概念：

chart：代表 helm 的包，可以看作：dnf  apt  brew...
Repostory：用来存放和共享 charts 的地方，可以看作：仓库地址
Release：是 kubernetes 中 chart 的实例，
理解总结：
helm 安装 charts 到 kubernetes 中，每次安装都会创建一个release,
可以在 helm 的 chart repositories 中寻找新的 chart

## 下载helm

[网址](helm.sh 'helm.sh')

操作步骤

![image-20240806100051239](https://gitee.com/xiaojinliaqi/img/raw/master/202408061000453.png)

![image-20240806100214203](https://gitee.com/xiaojinliaqi/img/raw/master/202408061002304.png)

![image-20240806100328546](https://gitee.com/xiaojinliaqi/img/raw/master/202408061003627.png)

下载完的包拷贝到server01

~~~shell
ls
tar -zxf helm-v3.15.3-linux-amd64.tar.gz 
cd linux-amd64/
mv helm /usr/local/sbin/
chmod +x /usr/local/sbin/helm 
source <(helm completion bash)
vim ~/.bashrc
在最后添加
source <(helm completion bash)
~~~

![image-20240806101648503](https://gitee.com/xiaojinliaqi/img/raw/master/202408061016604.png)

在server01上操作（可能会消耗时间）

~~~shell
helm repo add bitnami https://charts.bitnami.com/bitnami
~~~

~~~shell
helm repo list
~~~

![image-20240806145807472](https://gitee.com/xiaojinliaqi/img/raw/master/202408061458543.png)

~~~shell
# 搜索 Bitnami 仓库中的 MySQL Charts:
helm search repo bitnami | grep mysql

# 更新 Helm 仓库列表
helm repo update 

# 搜索 Helm 仓库中的 MySQL Charts
helm search repo bitnami | grep mysql

# 安装 MySQL Chart 并生成一个随机名称
helm install bitnami/mysql --generate-name

# 列出所有已安装的 Helm releases
helm list 

# 描述特定 Pod
kubectl describe pod mysql-1722928972-0 

# 查看特定 Helm release 的状态
helm status mysql-1722928972 

# v卸载特定 Helm release
helm uninstall mysql-1722928972 

# 搜索 Zookeeper Charts
helm search repo zookeeper

# 下载 Bitnami Zookeeper Chart
helm pull bitnami/zookeeper
ls

# 解压下载的 Zookeeper Chart 文件
tar -zxf zookeeper-13.4.10.tgz 

# 进入解压后的 Zookeeper 目录
cd zookeeper/
ls

# 编辑 values.yaml 文件
vim values.yaml 
700行true修改为false，250行1修改为3

# 安装 Zookeeper Chart
helm install zookeeper .

# 列出所有已安装的 Helm releases
helm list 

# 获取 Kubernetes Pods 列表
kubectl get pod

# 描述特定 Pod
kubectl describe pod zookeeper-0
kubectl get pod

# 搜索仓库中包含 "kafka" 的 Charts
helm search repo kafka

# 搜索并过滤 Bitnami 仓库中的 Kafka Charts
helm search repo kafka | grep bitnami/kafka

# 搜索带有详细信息的 Kafka Charts，并过滤 Bitnami 仓库中的 Kafka Charts
helm search repo kafka -l | grep bitnami/kafka

# 安装指定版本的 Kafka Chart 并设置自定义配置
helm install kafka bitnami/kafka --version 26.11.4 --set zookeeper.enabled=false --set controller.replicaCount=3 --set controller.persistence.enabled=false --set clusterDomain=cluster.local

#指定 release 的 values 配置。你要查看已经安装的名为 kafka 的 Helm release 的 values 配置
helm get values kafka

# 卸载名为 kafka 和 zookeeper 的 Helm releases
helm uninstall kafka zookeeper
~~~



~~~shell
# 创建新的 Helm chart
[root@server01 QOS]# helm create helm-test

# 进入 helm-test 目录
[root@server01 QOS]# cd helm-test/
[root@server01 helm-test]# ls
charts  Chart.yaml  templates  values.yaml

# 显示目录结构
[root@server01 helm-test]# tree
.
├── charts   #子 Charts 的目录（通常为空）
├── Chart.yaml   #Chart 的元数据文件
├── templates   #包含各种 Kubernetes 资源模板
│   ├── deployment.yaml   #部署模板
│   ├── _helpers.tpl   #自定义模板帮助函数
│   ├── hpa.yaml   #Horizontal Pod Autoscaler 模板
│   ├── ingress.yaml   #Ingress 资源模板
│   ├── NOTES.txt   # 安装说明
│   ├── serviceaccount.yaml   # 服务账户模板
│   ├── service.yaml   # 服务模板
│   └── tests
│       └── test-connection.yaml   #测试连接模板
└── values.yaml   #默认配置值文件

~~~



https://github.com/arttor/helmify/releases

![image-20240806181319027](https://gitee.com/xiaojinliaqi/img/raw/master/202408061813224.png)



~~~shell
tar -zxf helmify_Linux_x86_64.tar.gz
mv helmify /usr/local/sbin/
chmod +x /usr/local/sbin/helmify

mkdir 8_6
cd 8_6/
vim nginx.yaml 
###
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
###
# 将 nginx.yaml 文件的内容通过 helmify 工具转换为一个名为 nginx-li 的 Helm chart
cat nginx.yaml | helmify nginx-li

# 安装 Helm Chart 并生成名称
helm install nginx-li --generate-name
NAME: nginx-li-1722945331
LAST DEPLOYED: Tue Aug  6 19:55:31 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

# 显示 Pod 信息
kubectl infopod 
NAME                                       IP              NODE       IMAGE
nginx-li-1722945331-web-547cbcdfb9-8vszx   10.110.225.86   server02   nginx:1.24
nginx-li-1722945331-web-547cbcdfb9-lcp7t   10.110.225.85   server02   nginx:1.24
nginx-li-1722945331-web-547cbcdfb9-qzv9c   10.106.47.188   server03   nginx:1.24

#使用 cURL 测试服务
curl 10.110.225.86

# 打包 Helm Chart
helm package nginx-li

# 卸载指定 Helm Release
helm uninstall nginx-li-1722945331 

# 使用已打包的 Helm Chart 安装 release
helm install web-li nginx-li-0.1.0.tgz 
NAME: web-li
LAST DEPLOYED: Tue Aug  6 19:58:28 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

# 卸载新的 Helm Release
helm uninstall web-li 

~~~



### 什么是中间件？

中间件 = 平台 + 通信
分布式中间件：activeMQ  rabbitMQ  kafka  rocketMQ
负载均衡中间件：Nginx LVS   keepalived CDN
缓存中间件：Meecache redis
数据库中间件：MyCat Shareding JDBC



### helmify file:

Chart.yaml ：包含 chart 的信息，例如名字，版本，描述等
templates：包含安装 helm chart 时最终部署的所有清单文件
values.yaml：定义模板中的值，例如 replicas image 等等
Tips：
1.helmify 不会覆盖文件
2.helmify 不会删除现有模板文件，指挥覆盖（一个目录下只有一个模板）
3.helmify 的所有变更都从下一次部署开始
4.注意 labels 如果之前用了，最好从头开始重新生成

