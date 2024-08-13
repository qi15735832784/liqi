# kubernetes的框架/组件结构

---

![image-20240725215907947](https://gitee.com/xiaojinliaqi/img/raw/master/202407252159273.png)

分析上述架构图：

~~~
k8s在做框架结构的时候， 我们可以把节点，也就是说host主机被分成两种节点，第一种节点就是来做管理端的，也就是初始化集群，初始化了一个管理端，初始化管理端这个集群，我们把它叫做控制面板，也就是control-plane（康戳不累），它叫做控制面板，这个控制面板，对我们来讲就是我们的主控制节点，我们想做的功能，内容，都在我们的主控制面板上，那么然后分出来另外一个节点，叫其他节点，叫做work节点，其他节点叫做work节点，这是两个节点名称，控制面板用来下达指令，或做配置，或做修改，或使用命令的时候我们都在control-plane上面做，然后就有一个work节点，work节点就在pod里面添加我们需要工作的容器 ，容器要在里面工作，在我们work节点上进行添加使用工作，这样一个工作流程，那么这时候包括的组件有kubectl  get  pod  --namespace kube-system  这条命令就是可以查看到k8s的组件，然后要查看这些组件工作在主机的那个work节点上，使用kubectl  get  pod  --namespace kube-system -o wide 就可以看到组件，使用kubectl  get  pod  --namespace kube-system -o wide | grep k8s1 可以看到主控制上面的组件，也就是主节点，看到controllers就是控制面板，就是控制端，calico-node每个节点都有，因为它代表容器，它是容器对外的节点，coredns就是dns，etcd就是一个非关系型数据库，所有数据只有唯一的外流皮，和redis一样，写书数据叫set，读取数据叫get，k8s用get来查看，kube-apiserver就是应用服务器接口，他就是跟什么服务相连的东西，api就是微服务调用的一个接口，controllers-manager就是一个控制管理，proxy和docker的一样都是做数据转发，scheduler就是调度，我能调用什么，使用kubectl  get  pod  --namespace kube-system -o wide | grep k8s2 ，kubectl  get  pod  --namespace kube-system -o wide | grep k8s3  其他work节点， 就可以看到只有node容器的网络和把容器里的数据来回映射的proxy，k8s的组件包括kubelet，kubeadm，kubectl， kubeadm用来做管理集群，这个集群的添加，删除，kubectl叫做k8s的客户端工具，命令行工具，开k8s先开kubelet，k8s才能启动，kubelet有一个独立的k8s里面的内容，这个独立内容crlctl这个东西，crlctl 就是修改容器的底部，crictl是 kubetet 的客户端，管理容器和pod。也是修改kubernetes 容器基座的配置文件，kubelet 在集群种每个节点都启动，管理 pod和容器也是集群的哭护短agent，kubelet 采集主节点信息交给控制面板，kubectl create就是命令行工具，在容器里想使用什么东西需要kubectl create加进来，kubectl create创建一个内容连接到apiserver，apiserver太属于我们组件中的通讯，所有k8s的组件都要连接到apiserver上，进行通讯，发消息，连通，他支持http和https协议，kubectl create下达命令到apiserver，先找controller manager ，这个组件就是保证k8s种pod的正常运行，什么是pod控制器，他就是pod进程中，他就是pod进程中最小的单元，他调度的是service，
k8s最小的调度单元是pod，每个pod里面都有好多容器，pod在k8s就是同生同死的容器，servers放置的是各种各样的服务，pod不能放相同的服务，所有pod公用namespaces ，cgroup，cgroup不是完全相同，限制内存，cpu，pod在k8s就是同生同死的容器就是产生依赖关系，tomcat和mysql不属于同生同死的关系，controller manager用来处理pod的部署形式，这个pod按照什么形式，什么模式，开始进行处理，这个pod包括图里，控制器如何处理pod的运行，pod不可随意关闭，controller manager跟踪pod的运行，把pod的运行状态反馈回来，对pod进行调度和部署，kubectl create先到controller manager进行确认，把消息再交给scheduler，scheduler在调度容器去哪个节点上运行，就出现kubelet，controller manager确认运行方式，scheduler确认到哪个节点运行，他会把相关信息发过来，把镜像，卷，端口发过来，映射卷，端口，使用什么镜像，把三大件发送给kubelet，问什么发送给这个kubelet不发送给另一个kubelet，kubelet会把客户端信息发给etcd存储起来，kubelet安装好启动完成会采集这个节点的所有容器信息，也包括节点信息，采集完发送给apiserver，apiserver把kubelet这个aget存放到etcd里面，主机点会知道，先到etcd里面查找那个硬件资源大就发送给那个kubelet，充当aget的作用，采集资源信息并发送，这个时候kubelet调用kube-proxy，调用crictl这个程序，这个程序就会执行与容器相关的命令，创建一个pod ，一个容器，这个时候就可以创建起来，调用kubelet执行crictl，kubelet2个作用一个充当aget ，一个充当客户端，使用命令行工具创建容器，创建pod，proxy组件就是calico，他就是链接容器，让容器跨主机通讯，service把信息转发到容器里面，service链接proxy ，proxy使用iptabels做一个集群代理，把数据转发给多个pod，proxy转发数据。
或者
K8s的框架结构：host主机分成两种类别
管理端：在初始化集群时叫控制面板control-plane，想做的内容都在主控制节点上执行
其他节点work节点：控制面板上下达指令，添加需要工作的容器
包括的组件 kubectl get pod  --namespace kube-system 这就是k8s所需要的组件
Kubeadmin : 做管理集群的，集群的添加、删除或者集群的内容
kubelet： 有独立的内容 crictl     管理pod和容器也是集群的客户端agent
	crictl  是 kubelet 的客户端，管理容器和pod.也是修改Kubernetes 容器基座的配置文件。 
kubectl ：客户端的命令行工具 

当你希望在容器内执行什么东西时 需要kubectl create创建内容连接到apiserver上，apiserver
属于组件中 的通讯组件，所有k8s的组件都要连接到apiserver上 进行通讯，支持http和https协议。

首先要找control manager，这个组件用来保证k8s当中pod的正常运行。pod指计算机当中 pod进行一个正常工作，需要借助docker swarm 中的service来理解。service是docker swarm的最小工作单元，最小调度service  每个pod里面有多个容器在里面运行。 在k8s当中所有的容器都是以pod为单位的，将使共用nameapace 和cgroup。两者之间产生依赖关系的容器叫就做同生同死
 然后把消息交给scheduler调度，调度你当前的工作环境去哪一个节点去运行，把运行的相关信息发送给kubelet ，安装kubelet完成后
开始采集当前节点全部的容器信息。采集完成后会发送给apiserver，采集到的信息会存放到ectd。这时会调用crictl 的应用程序 创建pod的多个容器，calio是让主机跨主机通讯的网络 ，创建overlay网卡，一个是网络跨主机通信，一个是本地上网。service会把信息转发到容器里面，service连接到kube-proxy，它有一个工作原理iptables，使用iptables来做集群代理的方式，把数据转发到多个pod（外部访问由service完成）service转发到kube-proxy中的某一个容器（完成数据的转发）
~~~

~~~shell
#获取Kubernetes集群中kube-system命名空间下的所有Pod的详细信息。其中，kubectl get pod 是用于获取Pod的命令，--namespace kube-system 是指定要查询的命名空间为kube-system，-o wide 是设置输出格式为宽格式，以显示更多的信息
[root@server01 ~]# kubectl get pod --namespace kube-system -o wide
#主节点
[root@server01 ~]# kubectl get pod --namespace kube-system -o wide | grep server01
calico-kube-controllers-564985c589-hc58j
calico-node-q6g95                       
coredns-7b5944fdcf-6qz5q                
coredns-7b5944fdcf-r9r25                
etcd-server01                           
kube-apiserver-server01                 
kube-controller-manager-server01        
kube-proxy-9dt7p                        
kube-scheduler-server01                 
#work节点
[root@server01 ~]# kubectl get pod --namespace kube-system -o wide | grep server02
calico-node-8h9xf
kube-proxy-dnzrc 
[root@server01 ~]# kubectl get pod --namespace kube-system -o wide | grep server03
calico-node-p4cnq 
kube-proxy-v64cl 
~~~

基础语法

~~~shell
#kubectl [命令] [类型] [类型的名字] [类型的参数]
#kubectl [command] [TYPE] [TYPE-Name] [--TFlagsA] [--TFlagsB] ...
#创建一个名为test的Deployment对象。该Deployment将使用最新的nginx镜像，并创建3个副本
[root@server01 ~]# kubectl create deployment test --image nginx:latest --replicas 3
#列出当前集群中所有Pod的信息。运行此命令后，您将看到每个Pod的名称、状态、所在节点以及创建时间等信息
[root@server01 ~]# kubectl get pod
NAME                    READY   STATUS              RESTARTS   AGE
test-8677764bbc-528qc   0/1     ContainerCreating   0          24s
test-8677764bbc-vdq4m   0/1     ContainerCreating   0          24s
test-8677764bbc-vvqt4   1/1     Running             0          24s
#查看名为test-8677764bbc-528qc的Pod的详细信息。通过运行此命令，您可以获取有关该Pod的各种信息，例如其状态、标签、容器规格
kubectl describe pod test-8677764bbc-528qc
#查看有哪些空间
kubectl get namespaces
#查看容器的运行状态
kubectl logs test-8677764bbc-528qc  #容器名
~~~

查看错误的方式

~~~shell
pod:kubectl describe 后面的Events   #查看pod的状态
container: kubectl logs            #查看容器为什么没有启动
~~~

删除容器

~~~shell
kubectl delete pod box
~~~

~~~shell
#关于删除原则：谁创建的谁删除，pod 是有期望值的
kubectl delete pod box
kubectl delete deployments.apps test    #kubectl+命令+类型+类型名字
#强制删除
kubectl delete pod box1 --force --grace-period 0
#Kubernets 无法使用 bash 作为前台程序，依然遵循容器命令生命周期等于容器生命周期规则
~~~

登陆容器

~~~shell
# kubectl attach    登陆到容器的运行命令
# kubectl exec -it   作用仍然为在容器执行命令 
kubectl exec -it pods/box1 -- /bin/sh
~~~

# kubectl插件（注意节点）查询污点

~~~shell
[root@server01 ~]# vim kubectl-hello
#!/bin/bash
echo "The message show all nodes Taints:"
A=$(kubectl describe nodes server01 | grep -i taints | tr -s "")
B=$(kubectl describe nodes server02 | grep -i taints | tr -s "")
C=$(kubectl describe nodes server03 | grep -i taints | tr -s "")
echo "server01 $A"
echo "server02 $B"
echo "server03 $C"
或者
#!/bin/sh
echo "The message show all nodes taints:"
A=$(kubectl get node server01 -o jsonpath='{range .spec.taints[*]}{"\t"}{.key}={.value}:{.effect}{"\n"}{end}')
B=$(kubectl get node server02 -o jsonpath='{range .spec.taints[*]}{"\t"}{.key}={.value}:{.effect}{"\n"}{end}')
C=$(kubectl get node server03 -o jsonpath='{range .spec.taints[*]}{"\t"}{.key}={.value}:{.effect}{"\n"}{end}')
echo -e "server01:\n$A"
echo -e "server02:\n$B"
echo -e "server03:\n$C"
[root@server01 ~]# mv kubectl-hello /usr/local/sbin/
[root@server01 ~]# chmod +x /usr/local/sbin/kubectl-hello 
[root@server01 ~]# kubectl hello
#查看计算机当前有的插件
kubectl piugin list
~~~

API versions 官方网址

~~~shell
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.30/#-strong-api-groups-strong-
~~~

查看当前主机支持的API versions 

~~~shell
kubectl api-versions
~~~

nginx的.yaml文件（基础语法）

~~~shell
[root@server01 ~]# vim nginx.yaml
apiVersion: apps/v1        #指定API版本为apps/v1
kind: Deployment           #指定资源类型为Deployment
metadata:
  name: nginx-deployment   #指定Deployment的名称为nginx-deployment
spec:
  replicas: 3              #指定副本数量为3，即创建3个Nginx容器实例
  selector:
    matchLabels:
      app: nginx           #指定标签为app=nginx的Pods属于这个Deployment
  template:
    metadata:
      labels:
        app: nginx         #为Pods添加标签app=nginx
    spec:
      containers:
      - name: nginx            #指定容器名称为nginx
        image: nginx:1.24      #指定使用的镜像为nginx:1.24
        imagePullPolicy: IfNotPresent   #指定镜像拉取策略为IfNotPresent，即本地有镜像则使用本地镜像，否则从远程仓库拉取
        ports:
        - containerPort: 80       #指定容器的端口为80
~~~

部署nginx.yaml文件

~~~shell
[root@server01 ~]# kubectl apply -f nginx.yaml
[root@server01 ~]# kubectl get pod
~~~

![image-20240725231109452](https://gitee.com/xiaojinliaqi/img/raw/master/202407252311510.png)

获取语法

~~~shell
#创建一个名为 "newli" 的 Deployment，使用最新的 httpd 镜像。然后，它将生成的 Deployment 配置以 YAML 格式输出到名为 "test.yaml" 的文件中，通过模板创建
[root@server01 ~]# kubectl create deployment newli --image httpd:latest -o yaml --dry-run=client > test.yaml
	• kubectl create deployment: 这是 Kubernetes 的命令行工具 kubectl 的一部分，用于创建新的资源对象，如 Deployment。
	• newli: 这是要创建的 Deployment 的名称。
	• --image httpd:latest: 这个选项指定了要在 Deployment 中使用的镜像及其版本。在这个例子中，使用的是最新版本的 httpd 镜像。
	• -o yaml: 这个选项告诉 kubectl 将输出格式化为 YAML 格式。
	• --dry-run=client: 这个选项告诉 kubectl 在不实际创建资源的情况下运行命令。这对于验证命令是否正确以及预览将要创建的资源非常有用。
	• > test.yaml: 这个重定向操作符将命令的输出保存到名为 "test.yaml" 的文件中。
~~~

此时就会多出一个test.yaml的文件（模板自动生成）

![image-20240725231921594](https://gitee.com/xiaojinliaqi/img/raw/master/202407252319692.png)

~~~shell
[root@server01 ~]# vim test.yaml
apiVersion: apps/v1        #指定API版本为apps/v1
kind: Deployment           #指定API版本为apps/v1
metadata:
  labels:
    app: newli             #为Deployment添加标签app=newli
  name: newli              #指定Deployment的名称为newli
spec:
  replicas: 3              #指定副本数量为3，即创建3个容器实例
  selector:
    matchLabels:
      app: newli           #指定选择器匹配标签app=newli的Pods属于这个Deployment
  strategy: {}             #使用默认的更新策略（RollingUpdate）
  template:
    metadata:
      labels:
        app: newli         #为Pods添加标签app=newli
    spec:
      containers:
      - image: httpd:latest   #指定使用的镜像为httpd:latest
        name: httpd           #指定容器名称为httpd
        imagePullPolicy: IfNotPresent     #指定镜像拉取策略为IfNotPresent，即本地有镜像则使用本地镜像，否则从远程仓库拉取
        ports:
        - containerPort: 80    #指定容器的端口为80
status: {}                     #当前Deployment的状态信息为空
[root@server01 ~]# kubectl apply -f test.yaml
[root@server01 ~]# kubectl get pod
~~~

![image-20240725232132590](https://gitee.com/xiaojinliaqi/img/raw/master/202407252321632.png)

通过文件部署（通过文件删除）

~~~shell
[root@server01 ~]# kubectl delete -f test.yaml 
deployment.apps "newli" deleted
[root@server01 ~]# kubectl get pod
NAME                               READY   STATUS    RESTARTS   AGE
nginx-deployment-8588484f4-dv8mp   1/1     Running   0          15m
nginx-deployment-8588484f4-gwgfq   1/1     Running   0          15m
nginx-deployment-8588484f4-xc8tq   1/1     Running   0          15m
~~~

查询 kubernetes 命名空间

~~~shell
[root@server01 ~]# kubectl get namespaces
NAME              STATUS   AGE
default           Active   4d1h      #默认命名空间，如果没有指定命名空间，Pods将部署到这个命名空间
kube-node-lease   Active   4d1h      #存储节点租约的命名空间，节点租约用于跟踪节点的健康状态
kube-public       Active   4d1h      #公共命名空间，用于存放公共资源，如ConfigMaps和Secrets
kube-system       Active   4d1h      #系统命名空间，用于存放由Kubernetes系统组件创建的资源，如DNS服务、监控等
~~~

自建/创建命名空间

~~~shell
[root@server01 ~]# kubectl create namespace prod
[root@server01 ~]# kubectl get namespaces
NAME              STATUS   AGE
default           Active   4d1h
kube-node-lease   Active   4d1h
kube-public       Active   4d1h
kube-system       Active   4d1h
prod              Active   3d6h
~~~

把pod部署到刚才创建好的空间

~~~shell
[root@server01 ~]# vim pod.yaml 
aapiVersion: v1
kind: Pod
metadata:
  name: box            #Pod的名称，标识为“box”
  namespace: prod      #Pod所在的命名空间，这里是“prod”
  labels:
    app: myapp      #标签用于标识Pod，这里设置了标签“app”值为“myapp”，用于管理和选择Pod
spec:
  containers:
  - name: test1
    image: busybox:1.36
    imagePullPolicy: IfNotPresent
    command:                 #容器的启动命令，这里使用/bin/sh执行一个shell命令sleep 1d，让容器休眠1天
    - /bin/sh
    - -c
    - sleep 1d
  - name: test2
    image: busybox:1.36
    imagePullPolicy: IfNotPresent
    args: ["sleep","1d"]      #容器的启动参数，这里设置参数为“sleep”和“1d”，效果是让容器休眠1天
#总结:这个Pod配置定义了两个容器“test1”和“test2”，它们都使用“busybox:1.36”镜像，并且都设置为休眠1天。这两个容器在Pod内并行运行，共享网络和存储资源，但它们的执行方式略有不同：test1使用command字段指定了启动命令，这种方式更接近于直接在命令行中输入命令。test2使用args字段指定了启动参数，这些参数将传递给镜像默认的启动命令
~~~

==command==: 与==ENTRYPOINT==相同，用来执行命令

==args==: 与==CMD==相同，可以传递参数给 command

~~~shell
[root@server01 ~]# kubectl apply -f pod.yaml    #部署
[root@server01 ~]# kubectl get pod
[root@server01 ~]# kubectl get pod --namespace prod
~~~

![image-20240727001523636](https://gitee.com/xiaojinliaqi/img/raw/master/202407270015843.png)

查询prod详细信息

~~~shell
[root@server1 ~]# kubectl describe pod --namespace prod box
~~~

强制删除pod.yaml 文件重置配置文件

~~~shell
[root@server01 ~]# kubectl delete  -f pod.yaml --force --grace-period 0
###错误例子
[root@server01 ~]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: box
  namespace: prod
  labels:
    app: myapp
spec:
  containers:
  - name: test1
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
  - name: test2
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
[root@server1 ~]# kubectl apply -f pod.yaml
[root@server1 ~]# kubectl get pod --namespace prod
~~~

![image-20240727003112976](https://gitee.com/xiaojinliaqi/img/raw/master/202407270031083.png)

查看报错信息

~~~shell
[root@server1 ~]# kubectl describe pod --namespace prod box
~~~

![image-20240727003309630](https://gitee.com/xiaojinliaqi/img/raw/master/202407270033684.png)

查看容器日志报错

~~~shell
[root@server1 ~]# kubectl logs --namespace prod pods/box -c test2
#在输出的内容找报错信息
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
严重警告80端口错误  端口被占用
#由上可得是容器的错误
~~~

~~~shell
#删除pod.yaml部署的内容再次部署
[root@server1 ~]# kubectl delete  -f pod.yaml --force --grace-period 0
[root@server1 ~]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: box
spec:
  containers:
  - name: test1
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80    #仅用于service的标注，不生效（不代表实际的端口号）单纯的做了标注 端口号80
[root@server1 ~]# kubectl apply -f pod.yaml     #重新部署服务
[root@server01 ~]# kubectl get pod
NAME   READY   STATUS    RESTARTS      AGE
box    1/1     Running   1 (60s ago)   3d3h
[root@server01 ~]# kubectl get pod -o wide
NAME   READY   STATUS    RESTARTS      AGE    IP              NODE       NOMINATED NODE   READINESS GATES
box    1/1     Running   1 (72s ago)   3d3h   10.106.47.139   server03   <none>           <none>
~~~

访问10.106.47.139是k8s的内部地址，注意浏览器是访问不到的

![image-20240727005905289](https://gitee.com/xiaojinliaqi/img/raw/master/202407270059613.png)

如果想==临时性==的向里面转移一下也可以做到

~~~shell
#将本地的8080端口流量转发到名为"box"的Pod的80端口，使得你可以通过访问本地的8080端口来访问Pod的80端口
或者
#把所有的网段转到80端口上浏览器进行验证，就访问到nginx页面了
[root@server01 ~]# kubectl port-forward --address 0.0.0.0 box 8080:80
~~~

![image-20240727011131664](https://gitee.com/xiaojinliaqi/img/raw/master/202407270111718.png)