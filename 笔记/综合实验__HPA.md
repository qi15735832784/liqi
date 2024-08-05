# 综合实验__HPA



config and secret  Tips:

1. 引用的 key 必须存在
2. envFrom calueFrom 无法热更新
3. envFrom 配置环境环境变量，如果key 是无效的，它会忽略key
4. configmap 和 secret 必须要和pod 的引用在相同的 namespace 中
5. subPath 也无法热更新
6. configmap 和secret 尽量都小于 1MB

## 综合实验

~~~shell
[root@server01 ~]# mkdir secret
[root@server01 ~]# cd secret/
[root@server01 secret]# ls
[root@server01 secret]# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=www.lq.com"
[root@server01 secret]# kubectl create secret tls nginx-test-tls --key tls.key --cert tls.crt
[root@server01 secret]# kubectl run web --image nginx:latest --image-pull-policy IfNotPresent
[root@server01 secret]# kubectl exec web -- cat /etc/nginx/nginx.conf > nginx.conf
[root@server01 secret]# kubectl exec web -- cat /etc/nginx/conf.d/default.conf > default.conf
[root@server01 secret]# vim nginx.conf 
10行修改为512

server {
    listen       443 ssl;
    server_name  www.lq.com;

    ssl_certificate /etc/nginx/ssl/tls.crt;
    ssl_certificate_key /etc/nginx/ssl/tls.key;

    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded_For $proxy_add_x_forwarded_for;
    }





~~~





## pod 的 HPA  水平自动弹性伸缩

## Metrics server：

收集 kubelet 的指标，并且公开指标

供给 pod 自动水平扩缩（HPA）和自动垂直扩缩（VPA）

可以使用 kubectl pod 命令查看指标信息

仅用于自动扩缩为目的，监控软件自行安装其他采集 agent 



从 Kubernetes Metrics Server 的 GitHub 发布页面下载最新的 components.yaml 文件，这个文件包含了部署 Metrics Server 所需的 Kubernetes 资源定义（如 Deployments、Services 等）如果下载不下来直接拉包 

~~~shell
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
~~~

 [components.yaml](C:\Users\李琦\Downloads\components.yaml) 

编辑components.yaml，添加kubelet-insecure-tls，修改image

~~~shell
vim components.yaml
#- --kubelet-insecure-tls
#image: registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/metrics-server:v0.7.1
~~~

部署components.yaml

~~~sh
kubectl apply -f components.yaml
~~~

![image-20240805111520410](https://gitee.com/xiaojinliaqi/img/raw/master/202408051115500.png)

查询去哪台节下载镜像

~~~sh
kubectl get pod --namespace kube-system -o wide 
~~~

![image-20240805111642813](https://gitee.com/xiaojinliaqi/img/raw/master/202408051116860.png)

在server02节点上下载镜像

~~~sh
nerdctl pull --namespace k8s.io registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/metrics-server:v0.7.1
~~~

在server01主节点上再次查询是否Running

~~~sh
kubectl get pod --namespace kube-system
~~~

![image-20240805112422353](https://gitee.com/xiaojinliaqi/img/raw/master/202408051124396.png)

查询 Kubernetes 集群中各个节点的资源使用情况，包括 CPU 和内存使用情况

`NAME`：节点的名称。

`CPU(cores)`：节点当前使用的 CPU 量，以 milli-cores（千分之一核）为单位。比如 `236m` 表示 0.236 个 CPU 核。

`CPU%`：节点当前使用的 CPU 百分比。

`MEMORY(bytes)`：节点当前使用的内存量，以 MiB（Mebibytes）为单位。

`MEMORY%`：节点当前使用的内存百分比

~~~sh
kubectl top node
~~~

 ![image-20240805113640383](https://gitee.com/xiaojinliaqi/img/raw/master/202408051140412.png)





