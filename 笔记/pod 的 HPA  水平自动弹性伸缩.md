# pod 的 HPA  水平自动弹性伸缩

### Metrics server：

收集 kubelet 的指标，并且公开指标
供给 pod 自动水平扩缩（HPA）和自动垂直扩缩（VPA）
可以使用 kubectl pod 命令查看指标信息
仅用于自动扩缩为目的，监控软件自行安装其他采集 agent 
Tips:

1. 适用于集群单一部署
2. 每 15 秒采集一次指标
3. 占用 cpu 1 毫核和 2 MB 内存
4. 最多 5000 个 node 节点

从 Kubernetes Metrics Server 的 GitHub 发布页面下载最新的 components.yaml 文件，这个文件包含了部署 Metrics Server 所需的 Kubernetes 资源定义（如 Deployments、Services 等）如果下载不下来直接拉包 

~~~shell
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
~~~

 [components.yaml](C:\Users\李琦\Downloads\components.yaml) 

编辑components.yaml，140 行添加kubelet-insecure-tls，修改image

~~~shell
vim components.yaml
#- --kubelet-insecure-tls
#image: registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/metrics-server:v0.7.1
~~~

部署components.yaml

~~~shell
kubectl apply -f components.yaml
~~~

![image-20240805170842959](https://gitee.com/xiaojinliaqi/img/raw/master/202408051708022.png)

查询去哪台节下载镜像

~~~shell
kubectl get pod --namespace kube-system -o wide 
~~~

![image-20240805170910959](https://gitee.com/xiaojinliaqi/img/raw/master/202408051709998.png)

在server02节点上下载镜像

~~~sh
nerdctl pull --namespace k8s.io registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/metrics-server:v0.7.1
~~~

在server01主节点上再次查询是否Running

~~~sh
kubectl get pod --namespace kube-system
~~~

![image-20240805170937514](https://gitee.com/xiaojinliaqi/img/raw/master/202408051709563.png)

查询 Kubernetes 集群中各个节点的资源使用情况，包括 CPU 和内存使用情况

`NAME`：节点的名称。

`CPU(cores)`：节点当前使用的 CPU 量，以 milli-cores（千分之一核）为单位。比如 `236m` 表示 0.236 个 CPU 核。

`CPU%`：节点当前使用的 CPU 百分比。

`MEMORY(bytes)`：节点当前使用的内存量，以 MiB（Mebibytes）为单位。

`MEMORY%`：节点当前使用的内存百分比

~~~sh
kubectl top node
~~~

 ![image-20240805113640383](https://gitee.com/xiaojinliaqi/img/raw/master/202408051709002.png)

查询是否安装

~~~
kubectl get apiservices.apiregistration.k8s.io | grep metrics-server
kubectl get pod --namespace kube-system | grep metrics-server-6c9cb666c4-kc6kh
~~~

在server02创建文件以及页面拷贝到server03

~~~shell
mkdir html
vim html/index.php
<?php
 $x = 0.001;
 for ($i = 0; $i <= 1000000; $i++){
   $x += sqrt($x);
 }
  echo "OK!"
?>
scp html/index.php server03:/root/html/
~~~

在server02,server03拉取php镜像

~~~shell
nerdctl pull --namespace k8s.io registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/php:8-apache
~~~

在server01节点编辑hpa.yaml文件

~~~shell
vim hpa.yaml 
###
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/php:8-apache
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 400m
          requests:
            cpu: 200m
        volumeMounts:
        - name: index
          mountPath: /var/www/html
      volumes:
      - name: index
        hostPath:
          path: /root/html
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    app: php-apache
spec:
  ports:
  - port: 80
  selector:
    app: php-apache
~~~

部署hpa.yaml文件

~~~shell
kubectl apply -f hpa.yaml
~~~

curl访问

~~~shell
curl 10.100.156.154
~~~

![image-20240805163847666](https://gitee.com/xiaojinliaqi/img/raw/master/202408051709147.png)

自动伸缩

~~~shell
#为名为 web 的部署创建了一个自动水平扩展（HPA）配置
kubectl autoscale deployment web --cpu-percent=10 --min 1 --max 10
~~~

测试

~~~shell
#创建一个临时的 Pod，并执行一个简单的负载生成任务。具体来说，它创建了一个使用 busybox 镜像的 Pod，并在其中运行一个无限循环的 wget 命令来向名为 php-apache 的服务发出请求
kubectl run -it load-viwe --rm --image busybox:latest --image-pull-policy IfNotPresent --restart Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
~~~





