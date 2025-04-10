# Service

1. ## 服务发现
	
	1. ### pod 的扩缩可以在 service 的 endpoints 中实现变更
	2. ### 无状态的 pod 可以任意扩缩，有状态的 pod 需要考虑数据部分
2. ## cluster IP 是虚拟IP，可以访问，但不可以ping
	
	1. ### 使用 iptables 转发数据到 pod
	2. ### 使用 iptables 的概率转发，不是 RR 转发（ipvs 是 RR 转发）

clusterIP：None 表示无头服务（Headless Servive）

不需要负载均衡及单独的 clusterIP 的时候使用（不与 kubernets 绑定）
通过 DNS 对应多地址解析完成（DNS RR，意味着仅可以通过域名访问）

## 实验部分



~~~shell
[root@server01 8_1]# vim nginx.yaml 
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
[root@server01 8_1]# kubectl apply -f nginx.yaml 
deployment.apps/web created
[root@server01 8_1]# kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
web-8588484f4-cl7bh   1/1     Running   0          104s
web-8588484f4-whmrf   1/1     Running   0          104s
web-8588484f4-xd7vw   1/1     Running   0          104s

##在名为web-8588484f4-cl7bh的Pod中执行bash
[root@server01 8_1]# kubectl exec -it web-8588484f4-cl7bh -- bash
root@web-8588484f4-cl7bh:/# cat /etc/resolv.conf 
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

##获取Kubernetes系统中名为kube-system的命名空间下的所有服务
[root@server01 8_1]# kubectl get service --namespace kube-system 
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   9d

##获取Kubernetes系统中名为kube-system的命名空间下名为kube-dns的服务的详细信息
[root@server01 8_1]# kubectl describe service --namespace kube-system kube-dns 
Name:              kube-dns
Namespace:         kube-system   #服务所在的命名空间
Labels:            k8s-app=kube-dns   #用于标识和分类这个服务的标签
                   kubernetes.io/cluster-service=true
                   kubernetes.io/name=CoreDNS
Annotations:       prometheus.io/port: 9153   #附加的元数据信息
                   prometheus.io/scrape: true
Selector:          k8s-app=kube-dns   #用于选择后端 Pod 的标签选择器
Type:              ClusterIP   #服务类型，这里是集群内部IP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.0.10   #服务的集群内部IP地址
IPs:               10.96.0.10
Port:              dns  53/UDP   #DNS: UDP 53端口
TargetPort:        53/UDP
Endpoints:         10.105.199.4:53,10.105.199.5:53   #后端 Pod 的 IP 地址和端口
Port:              dns-tcp  53/TCP   #TCP 53端口
TargetPort:        53/TCP
Endpoints:         10.105.199.4:53,10.105.199.5:53
Port:              metrics  9153/TCP   #TCP 9153端口
TargetPort:        9153/TCP
Endpoints:         10.105.199.4:9153,10.105.199.5:9153
Session Affinity:  None   #没有会话亲和性
Events:            <none>

##获取Kubernetes系统中名为kube-system的命名空间下所有包含"dns"关键字的Pod，并以宽格式输出结果
[root@server01 8_1]# kubectl get pod --namespace kube-system -o wide | grep dns
coredns-7b5944fdcf-6qz5q                   1/1     Running   1 (8h ago)   9d    10.105.199.4   server01   <none>           <none>
coredns-7b5944fdcf-r9r25                   1/1     Running   1 (8h ago)   9d    10.105.199.5   server01   <none>           <none>
~~~



~~~shell
[root@server01 8_1]# vim nginx-svc.yaml
apiVersion: v1
kind: Service
metadata: 
  name: nginxsvc
spec:
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  selector:
    app: nginx
[root@server01 8_1]# kubectl apply -f nginx-svc.yaml 
service/nginxsvc created
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP    9d
nginxsvc     ClusterIP   10.111.62.128   <none>        8080/TCP   89s
#去server02节点
[root@server02 ~]# crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD
2c2ddd5a71317       6c0218f168766       28 minutes ago      Running             nginx               0                   6f721158c903f       web-8588484f4-cl7bh
d9cc3780427fe       4e42b6f329bc1       9 hours ago         Running             calico-node         1                   16a417bfad179       calico-node-8h9xf
4a26649162c3d       747097150317f       9 hours ago         Running             kube-proxy          1                   3ef49913258f1       kube-proxy-dnzrc
[root@server02 ~]# crictl inspect 2c2ddd5a71317 
里面查看
        "env": [
          "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",   #标准的系统路径变量，定义了可执行文件的搜索路径
          "HOSTNAME=web-8588484f4-cl7bh",   #容器的主机名，这里是 "web-8588484f4-cl7bh"，看起来是一个 Kubernetes Pod 的名称
          "NGINX_VERSION=1.24.0",   #Nginx 版本，为 1.24.0
          "NJS_VERSION=0.7.12",   #NJS 版本，为 0.7.12
          "PKG_RELEASE=1~bullseye",   #pkg-centric package management system的版本，为 1~bullseye
          "KUBERNETES_PORT=tcp://10.96.0.1:443",   #Kubernetes 集群的 TCP 端口，为 tcp://10.96.0.1:443
          "KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443",   
          "KUBERNETES_PORT_443_TCP_PROTO=tcp",   #TCP 端口环境变量，为 tcp
          "KUBERNETES_PORT_443_TCP_PORT=443",   #TCP 端口的数字部分，为 443
          "KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1",   #TCP 端口的网络地址，为 10.96.0.1
          "KUBERNETES_SERVICE_HOST=10.96.0.1",   #Kubernetes 服务的网络地址，为 10.96.0.1
          "KUBERNETES_SERVICE_PORT=443",   #Kubernetes 服务的 TCP 端口，为 443
          "KUBERNETES_SERVICE_PORT_HTTPS=443"   #Kubernetes 服务的 HTTPS 端口，为 443
        ],
#在里面找cd找到的路径
          "destination": "/etc/resolv.conf",
          "type": "bind",
          "source": "/var/lib/containerd/io.containerd.grpc.v1.cri/sandboxes/6f721158c903f5a3bd567358202c925fa85b0883d0c6bfc8a8b94b439e6fcdc2/resolv.conf",
          "options": [
            "rbind",
            "rprivate",
            "rw"
          ]
        },
[root@server02 ~]# cd /var/lib/containerd/io.containerd.grpc.v1.cri/sandboxes/6f721158c903f5a3bd567358202c925fa85b0883d0c6bfc8a8b94b439e6fcdc2/
[root@server02 6f721158c903f5a3bd567358202c925fa85b0883d0c6bfc8a8b94b439e6fcdc2]# ls
hostname  hosts  resolv.conf
[root@server02 6f721158c903f5a3bd567358202c925fa85b0883d0c6bfc8a8b94b439e6fcdc2]# cat hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.15.200.11 server01
10.15.200.12 server02
10.15.200.13 server03
[root@server02 6f721158c903f5a3bd567358202c925fa85b0883d0c6bfc8a8b94b439e6fcdc2]# cat resolv.conf 
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
~~~

### 在不同空间内DNS带来的影响

~~~shell
[root@server01 8_1]# kubectl create namespace test
[root@server01 8_1]# vim test.yaml 
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: newli
  namespace: test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: newli
  strategy: {}
  template:
    metadata:
      labels:
        app: newli
    spec:
      containers:
      - image: httpd:latest
        name: httpd
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ns-svc
  namespace: test
spec:
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  selector:
    app: newli
[root@server01 8_1]# kubectl apply -f test.yaml 
[root@server01 8_1]# kubectl get pod --namespace test 
NAME                    READY   STATUS    RESTARTS   AGE
newli-5ffb4df5f-7nhx9   1/1     Running   0          66s
newli-5ffb4df5f-cncsd   1/1     Running   0          66s
newli-5ffb4df5f-kjh4t   1/1     Running   0          66s
[root@server01 8_1]# kubectl get service --namespace test 
NAME     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
ns-svc   ClusterIP   10.108.142.89   <none>        8080/TCP   2m26s

##在Kubernetes集群中运行一个名为box的临时容器，该容器使用busybox:1.36镜像，并在容器内执行/bin/sh
[root@server01 8_1]# kubectl run box --rm -it --image busybox:1.36 /bin/sh
/ # cat /etc/resolv.conf    #查看了容器内的/etc/resolv.conf文件，该文件包含了DNS解析的配置信息
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
/ # nslookup ns-svc.test
Server:         10.96.0.10
Address:        10.96.0.10:53

##在Kubernetes集群中运行一个名为box的临时容器，该容器使用rockylinux:9镜像，并在容器内执行/bin/bash。同时，设置了镜像拉取策略为IfNotPresent，表示如果本地已经存在该镜像，则不会从远程仓库拉取
[root@server01 8_1]# kubectl run box --rm -it --image rockylinux:9 --image-pull-policy IfNotPresent -- /bin/bash
If you don't see a command prompt, try pressing enter.
[root@box /]# cat /etc/resolv.conf    #查看了容器内的/etc/resolv.conf文件，该文件包含了DNS解析的配置信息
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
[root@box /]# dnf install bind-utils -yq   #安装了bind-utils软件包，这是一个用于查询DNS的工具
[root@box /]# nslookup ns-svc.test   #查询了一个名为ns-svc.test的服务的IP地址
Server:         10.96.0.10
Address:        10.96.0.10#53
Name:   ns-svc.test.svc.cluster.local
Address: 10.108.142.89
[root@box /]# curl ns-svc.test:8080   #使用curl命令访问了ns-svc.test服务上的8080端口
<html><body><h1>It works!</h1></body></html>
~~~



~~~shell
[root@server01 8_1]# vim domainame.yaml 
apiVersion: v1
kind: Service
metadata:
  name: default-subdomain   #名称: default-subdomain
spec:
  selector:
    name: busybox   #选择器: name=busybox
  clusterIP: None   #这是一个无头服务
  ports:
  - name: foo
    port: 1234
    targetPort: 1234
---
apiVersion: v1
kind: Pod
metadata:
  name: box1
  labels:
    name: busybox
spec:
  hostname: busybox-1
  subdomain: default-subdomain    #子域名: default-subdomain
  containers:
  - name: test1
    image: rockylinux:9
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
---
apiVersion: v1
kind: Pod
metadata:
  name: box2
  labels:
    name: busybox
spec:
  hostname: busybox-2
  subdomain: default-subdomain
  containers:
  - name: test2
    image: rockylinux:9 
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
[root@server01 8_1]# kubectl apply -f domainame.yaml 
service/default-subdomain created
pod/box1 created
pod/box2 created
[root@server01 8_1]# kubectl get pod
NAME   READY   STATUS    RESTARTS   AGE
box1   1/1     Running   0          9s
box2   1/1     Running   0          9s

##去server03上解析百度
[root@server03 ~]# nslookup www.baidu.com
Server:         10.15.200.2
Address:        10.15.200.2#53
Non-authoritative answer:
www.baidu.com   canonical name = www.a.shifen.com.
Name:   www.a.shifen.com
Address: 183.240.98.198
Name:   www.a.shifen.com
Address: 183.240.98.161
Name:   www.a.shifen.com
Address: 2409:8c54:870:34e:0:ff:b024:1916
Name:   www.a.shifen.com
Address: 2409:8c54:870:67:0:ff:b0c2:ad75

[root@server01 8_1]# kubectl get service   #显示了集群中的所有服务,可以看到 default-subdomain 服务，它的 CLUSTER-IP 是 None，这确认了它是一个无头服务
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
default-subdomain   ClusterIP   None            <none>        1234/TCP   5m50s
kubernetes          ClusterIP   10.96.0.1       <none>        443/TCP    9d
nginxsvc            ClusterIP   10.111.62.128   <none>        8080/TCP   96m
[root@server01 8_1]# kubectl infopod    #显示了 box1 和 box2 两个 Pod 的 IP 地址和所在节点
NAME   IP              NODE       IMAGE
box1   10.106.47.140   server03   rockylinux:9
box2   10.110.225.75   server02   rockylinux:9
[root@server01 8_1]# kubectl describe service default-subdomain 
Name:              default-subdomain
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          name=busybox
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                None
IPs:               None
Port:              foo  1234/TCP
TargetPort:        1234/TCP
Endpoints:         10.106.47.140:1234,10.110.225.75:1234   #显示了与此服务关联的 Pod 的 IP 地址和端口
Session Affinity:  None
Events:            <none>
[root@busybox-1 /]# nslookup default-subdomain
Server:         10.96.0.10
Address:        10.96.0.10#53
Name:   default-subdomain.default.svc.cluster.local
Address: 10.106.47.140
Name:   default-subdomain.default.svc.cluster.local
Address: 10.110.225.75
#也可以这样子
[root@busybox-1 /]# nslookup busybox-1.default-subdomain
Server:         10.96.0.10
Address:        10.96.0.10#53
Name:   busybox-1.default-subdomain.default.svc.cluster.local
Address: 10.106.47.140
[root@busybox-1 /]# nslookup busybox-2.default-subdomain
Server:         10.96.0.10
Address:        10.96.0.10#53
Name:   busybox-2.default-subdomain.default.svc.cluster.local
Address: 10.110.225.75
[root@server01 8_1]# kubectl delete -f domainame.yaml 
~~~



~~~shell
[root@server01 8_1]# vim domainame.yaml 
apiVersion: v1
kind: Service
metadata:
  name: default-subdomain
spec:
  selector:
    name: busybox
  clusterIP: None
  ports:
  - name: foo
    port: 1234
    targetPort: 1234
---
apiVersion: v1
kind: Pod
metadata:
  name: box1
  labels:
    name: busybox
spec:
  hostname: busybox-1
  subdomain: default-subdomain
  containers:
  - name: test1
    image: rockylinux:9
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
---
apiVersion: v1
kind: Pod
metadata:
  name: box2
  labels:
    name: busybox
spec:
  hostname: busybox-2
  setHostnameAsFQDN: true   #为 Pod 指定了一个子域名。这个子域名与 Pod 的 hostname 一起使用，形成 Pod 的完全限定域名 (FQDN)
  subdomain: default-subdomain
  containers:
  - name: test2
    image: rockylinux:9 
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
[root@server01 8_1]# kubectl apply -f domainame.yaml 
##这条命令在名为box1的Pod中启动了一个交互式bash会话
[root@server01 8_1]# kubectl exec -it box1 -- bash   
[root@busybox-1 /]# hostname   #在box1中执行hostname命令，返回结果是"busybox-1"，这是Pod的简短主机名
busybox-1
[root@busybox-1 /]# hostname -f
busybox-1.default-subdomain.default.svc.cluster.local
[root@busybox-1 /]# exit
exit
[root@server01 8_1]# kubectl exec -it box2 -- bash
[root@busybox-2 /]# hostname   #在box2中执行hostname和hostname -f命令，两者都返回了完整的域名
busybox-2.default-subdomain.default.svc.cluster.local
[root@busybox-2 /]# hostname -f
busybox-2.default-subdomain.default.svc.cluster.local
[root@server01 8_1]# kubectl delete -f domainame.yaml --force --grace-period 0

##解释Kubernetes中Pod的DNS策略。DNS策略决定了Pod中的容器如何解析DNS名称
[root@server01 8_1]# kubectl explain pod.spec.dnsPolicy
~~~



~~~shell
##部署前面的nginx.yaml文件
[root@server01 8_1]# kubectl apply -f nginx.yaml 
[root@server01 ~]# kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP    9d
nginxsvc     ClusterIP   10.111.62.128   <none>        8080/TCP   5h17m
[root@server01 ~]# curl 10.111.62.128:8080
[root@server01 8_1]# vim domainame.yaml 
apiVersion: v1
kind: Service
metadata:
  name: default-subdomain
spec:
  selector:
    name: busybox
  clusterIP: None
  ports:
  - name: foo
    port: 1234
    targetPort: 1234
---
apiVersion: v1
kind: Pod
metadata:
  name: box1
  labels:
    name: busybox
spec:
  hostNetwork: true   #指定 Pod 使用主机网络
  dnsPolicy: ClusterFirstWithHostNet   #指定 Pod 的 DNS 策略，设为 ClusterFirstWithHostNet 表示优先使用集群 DNS，失败后使用主机 DNS
  hostname: busybox-1
  subdomain: default-subdomain
  containers:
  - name: test1
    image: rockylinux:9
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
---
apiVersion: v1
kind: Pod
metadata:
  name: box2
  labels:
    name: busybox
spec:
  hostNetwork: true   #指定 Pod 使用主机网络
  hostname: busybox-2
  subdomain: default-subdomain
  containers:
  - name: test2
    image: rockylinux:9 
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
[root@server01 8_1]# kubectl apply -f domainame.yaml 
[root@server01 8_1]# kubectl get service
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
default-subdomain   ClusterIP   None            <none>        1234/TCP   7m28s
kubernetes          ClusterIP   10.96.0.1       <none>        443/TCP    9d
nginxsvc            ClusterIP   10.111.62.128   <none>        8080/TCP   5h31m 
[root@server01 8_1]# kubectl exec -it box1 -- bash
[root@server02 /]# cat /etc/resolv.conf 
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
[root@server02 /]# curl nginxsvc.default:8080
[root@server02 /]# dnf install iproute -yq
[root@server02 /]# ip a
inet 10.15.200.12/24 brd 10.15.200.255 scope global noprefixroute ens160
inet 10.110.225.64/32 scope global tunl0
[root@server01 8_1]# kubectl exec -it box2 -- bash
[root@server03 /]# curl nginxsvc.default:8080
curl: (6) Could not resolve host: nginxsvc.default
[root@server01 8_1]# kubectl delete -f domainame.yaml --force --grace-period 0
~~~



~~~shell
[root@server01 8_1]# vim domainame.yaml 
apiVersion: v1
kind: Service
metadata:
  name: default-subdomain
spec:
  selector:
    name: busybox
  clusterIP: None
  ports:
  - name: foo
    port: 1234
    targetPort: 1234
---
apiVersion: v1
kind: Pod
metadata:
  name: box1
  labels:
    name: busybox
spec:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
  hostname: busybox-1
  subdomain: default-subdomain
  containers:
  - name: test1
    image: rockylinux:9
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
---
apiVersion: v1
kind: Pod
metadata:
  name: box2
  labels:
    name: busybox
spec:
  dnsPolicy: None   #这表示禁用 Kubernetes 默认的 DNS 策略
  dnsConfig:   #这个字段用于自定义 Pod 的 DNS 配置
    nameservers:   #这里定义了 Pod 将要使用的 DNS 服务器
    - 114.114.114.114   #公共 DNS 服务器
    - 8.8.8.8   #Google 的公共 DNS 服务器
  hostname: busybox-2
  subdomain: default-subdomain
  containers:
  - name: test2
    image: rockylinux:9 
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
[root@server01 8_1]# kubectl apply -f domainame.yaml
[root@server01 8_1]# kubectl exec -it box2 -- bash
[root@busybox-2 /]# cat /etc/resolv.conf 
nameserver 114.114.114.114
nameserver 8.8.8.8
[root@busybox-2 /]# curl nginxsvc.default:8080
curl: (6) Could not resolve host: nginxsvc.default
[root@busybox-2 /]# curl www.baidu.com
[root@server01 8_1]# kubectl infopod 
NAME                  IP              NODE       IMAGE
box1                  10.15.200.12    server02   rockylinux:9
box2                  10.106.47.144   server03   rockylinux:9
web-8588484f4-5928q   10.106.47.143   server03   nginx:1.24
web-8588484f4-9mqfq   10.110.225.77   server02   nginx:1.24
web-8588484f4-9rtp9   10.106.47.142   server03   nginx:1.24
##去server03节点
[root@server03 ~]# crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD
ae868a36fde8b       9cc24f05f3095       6 minutes ago       Running             test2               0                   9146212deb98a       box2
1ee91f088295b       6c0218f168766       4 hours ago         Running             nginx               0                   714110b4a47a3       web-8588484f4-5928q
ca1a5396d73f1       6c0218f168766       4 hours ago         Running             nginx               0                   c23e1bdd4b714       web-8588484f4-9rtp9
b235ddbdd65a9       4e42b6f329bc1       15 hours ago        Running             calico-node         1                   b2f570b5ca45c       calico-node-p4cnq
21d6e7bb8ce02       747097150317f       15 hours ago        Running             kube-proxy          1                   447d9bc0e27a0       kube-proxy-v64cl
[root@server03 ~]# crictl inspect ae868a36fde8b
[root@server03 ~]# cd /var/lib/containerd/io.containerd.grpc.v1.cri/sandboxes/9146212deb98ac5d2a56bf5233881abb199f73c6c483525dd1800d12a398a330/
[root@server03 9146212deb98ac5d2a56bf5233881abb199f73c6c483525dd1800d12a398a330]# ls
hostname  hosts  resolv.conf
[root@server03 9146212deb98ac5d2a56bf5233881abb199f73c6c483525dd1800d12a398a330]# cat resolv.conf 
nameserver 114.114.114.114
nameserver 8.8.8.8
[root@server01 8_1]# kubectl delete -f domainame.yaml --force --grace-period 0
~~~

service其他的设置（亲和性）期望值轮询状态

~~~shell
[root@server01 8_1]# kubectl delete -f nginx-svc.yaml 
service "nginxsvc" deleted
[root@server01 8_1]# vim nginx-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginxsvc
spec:
  sessionAffinity: ClientIP
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  selector:
    app: nginx
[root@server01 8_1]# kubectl apply -f nginx-svc.yaml 
service/nginxsvc created
[root@server01 8_1]# kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
web-8588484f4-5928q   1/1     Running   0          4h30m
web-8588484f4-9mqfq   1/1     Running   0          4h30m
web-8588484f4-9rtp9   1/1     Running   0          4h30m
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP    9d
nginxsvc     ClusterIP   10.96.244.87   <none>        8080/TCP   41s
[root@server01 8_1]# kubectl describe service nginxsvc 
Name:              nginxsvc
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          app=nginx
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.244.87
IPs:               10.96.244.87
Port:              <unset>  8080/TCP
TargetPort:        80/TCP
Endpoints:         10.106.47.142:80,10.106.47.143:80,10.110.225.77:80
Session Affinity:  ClientIP
Events:            <none>
[root@server01 8_1]# curl 10.96.244.87:8080
[root@server01 8_1]# kubectl logs web-8588484f4-5928q
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP    9d
nginxsvc     ClusterIP   10.96.244.87   <none>        8080/TCP   7m20s
~~~

手动设置（指定地址段，不指定的话就会变）

~~~shell
[root@server01 8_1]# kubectl delete -f nginx-svc.yaml 
[root@server01 8_1]# vim nginx-svc.yaml 
apiVersion: v1
kind: Service
metadata: 
  name: nginxsvc
spec:
  clusterIP: 10.10.100.100
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  selector:
    app: nginx
[root@server01 8_1]# kubectl apply -f nginx-svc.yaml 
The Service "nginxsvc" is invalid: spec.clusterIPs: Invalid value: []string{"10.10.100.100"}: failed to allocate IP 10.10.100.100: the provided IP (10.10.100.100) is not in the valid range. The range of valid IPs is 10.96.0.0/12

[root@server01 8_1]# vim /etc/kubernetes/manifests/kube-apiserver.yaml
#修改40行：- --service-cluster-ip-range=10.100.0.0/16
[root@server01 8_1]# systemctl daemon-reload 
[root@server01 8_1]# systemctl restart kubelet.service 
[root@server01 8_1]# vim nginx-svc.yaml  
apiVersion: v1
kind: Service
metadata: 
  name: nginxsvc
spec:
  clusterIP: 10.100.100.100
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  selector:
    app: nginx
[root@server01 8_1]# kubectl apply -f nginx-svc.yaml 
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP    9d
nginxsvc     ClusterIP   10.100.100.100   <none>        8080/TCP   16s
[root@server01 8_1]# curl 10.100.100.100:8080
[root@server01 8_1]# kubectl delete -f nginx-svc.yaml 
service "nginxsvc" deleted
[root@server01 8_1]# vim nginx-svc.yaml 
apiVersion: v1
kind: Service
metadata: 
  name: nginxsvc
spec:
  #clusterIP: 10.100.100.100
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  selector:
    app: nginx
[root@server01 8_1]# kubectl apply -f nginx-svc.yaml 
service/nginxsvc created
[root@server01 8_1]# kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
web-8588484f4-5928q   1/1     Running   0          5h1m
web-8588484f4-9mqfq   1/1     Running   0          5h1m
web-8588484f4-9rtp9   1/1     Running   0          5h1m
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP    9d
nginxsvc     ClusterIP   10.100.142.207   <none>        8080/TCP   13s
~~~

希望nginxsvc的cluster的IP访问外网

~~~shell
[root@server01 8_1]# vim nginx-svc.yaml 
apiVersion: v1
kind: Service
metadata: 
  name: nginxsvc
spec:
  #clusterIP: 10.100.100.100
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  selector:
    app: nginx
  externalIPs:
  - 10.15.200.11
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP    PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1       <none>         443/TCP    9d
nginxsvc     ClusterIP   10.100.74.220   10.15.200.11   8080/TCP   22s
#宿主机访问10.15.200.11:8080
~~~

![image-20240801173309442](https://gitee.com/xiaojinliaqi/img/raw/master/202408011733543.png)

还可以添加地址

~~~shell
[root@server01 8_1]# vim nginx-svc.yaml 
apiVersion: v1
kind: Service
metadata: 
  name: nginxsvc
spec:
  #clusterIP: 10.100.100.100
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  selector:
    app: nginx
  externalIPs:
  - 10.15.200.11
  - 10.15.200.100
[root@server01 8_1]# kubectl apply -f nginx-svc.yaml 
service/nginxsvc created
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP                  PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1       <none>                       443/TCP    9d
nginxsvc     ClusterIP   10.100.31.115   10.15.200.11,10.15.200.100   8080/TCP   10s
[root@server01 8_1]# curl 10.15.200.100:8080
~~~

容器内可以访问，容器外不能访问10.15.200.100:8080

![image-20240801173752605](https://gitee.com/xiaojinliaqi/img/raw/master/202408011737667.png)

![image-20240801173823660](https://gitee.com/xiaojinliaqi/img/raw/master/202408011738717.png)

server03安装apache

~~~shell
[root@server03 ~]# dnf install httpd -yq
[root@server03 ~]# systemctl start httpd
[root@server03 ~]# cd /var/www/html/
[root@server03 html]# echo "Im apache server in server03 by lisir" > index.html
[root@server03 html]# cd
[root@server03 ~]# curl 10.15.200.13

##server01部署
[root@server01 8_1]# vim ex-svc.yaml 
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Endpoints
metadata:
  name: my-service
subsets:
- addresses:
  - ip: 10.15.200.13
  ports:
  - port: 80
[root@server01 8_1]# kubectl apply -f ex-svc.yaml 
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP    9d
my-service   ClusterIP   10.100.52.144   <none>        80/TCP     100s
nginxsvc     ClusterIP   10.100.19.66    <none>        8080/TCP   13m
[root@server01 8_1]# kubectl describe service my-service 
Name:              my-service
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          <none>
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.100.52.144
IPs:               10.100.52.144
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         10.15.200.13:80   #代理前面指定的ip
Session Affinity:  None
Events:            <none>
[root@server01 8_1]# kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP    9d
my-service   ClusterIP   10.100.52.144   <none>        80/TCP     4m14s
nginxsvc     ClusterIP   10.100.19.66    <none>        8080/TCP   15m
[root@server01 8_1]# curl 10.100.52.144
Im apache server in server03 by lisir
[root@server01 8_1]# vim domainame.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: box1
  labels:
    name: busybox
spec:
  containers:
  - name: test1
    image: rockylinux:9
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
---
apiVersion: v1
kind: Pod
metadata:
  name: box2
  labels:
    name: busybox
spec:
  containers:
  - name: test2
    image: rockylinux:9 
    imagePullPolicy: IfNotPresent
    command:
    - sleep
    - 1d
[root@server01 8_1]# kubectl apply -f domainame.yaml 
pod/box1 created
pod/box2 created
[root@server01 8_1]# kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
box1                  1/1     Running   0          9s
box2                  1/1     Running   0          9s
web-8588484f4-5928q   1/1     Running   0          5h38m
web-8588484f4-9mqfq   1/1     Running   0          5h38m
web-8588484f4-9rtp9   1/1     Running   0          5h38m
[root@server01 8_1]# kubectl exec -it box1 -- bash
[root@box1 /]# curl my-service.default
Im apache server in server03 by lisir
~~~





