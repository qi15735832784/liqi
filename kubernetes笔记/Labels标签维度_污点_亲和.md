# Labels标签维度

```test
基于应用的横向维度（不同的POD有不同的标签）
基于版本的纵向维度（同一个POD 有不同的版本）
```

![image-20240727162608178](https://gitee.com/xiaojinliaqi/img/raw/master/202407271626424.png)

```test
key：必须小于63字符，不许字母和字符开头结尾  可以包含_. 字母和数字
Key+value不得超过253个字符 总长度256：= / . 去掉标点符号是253 
```

查询标签

```shell
[root@server01 ~]# kubectl get nodes --show-labels 
NAME       STATUS   ROLES           AGE     VERSION   LABELS
server01   Ready    control-plane   4d18h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server01,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
server02   Ready    <none>          4d17h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server02,kubernetes.io/os=linux
server03   Ready    <none>          4d17h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server03,kubernetes.io/os=linux

```

label：

[DomainName] / [Key] = [Value]

Kubernetes.io \ k8s.io 表示系统标签，尽量不要更改（操作系统加进来的）

```shell
pod-template-hash=8665b6f747:
表示：yaml 文件中 template 以下的文本的hash 值（hash值发生变化则会触发滚动更新）
```

实验演示

~~~shell
[root@server01 ~]# vim pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: box
  labels:
    app: as
    rel: stable
spec:
  containers:
  - name: test1
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
#这是一个Kubernetes的Pod配置文件，用于创建一个名为"box"的Pod。这个Pod包含一个名为"test1"的容器，使用"nginx:1.24"镜像，并设置了镜像拉取策略为"IfNotPresent"，表示如果本地不存在该镜像，则从远程仓库拉取。容器监听80端口。同时，这个Pod还包含了两个标签，分别是app: as和rel: stable
[root@server01 ~]# kubectl apply -f pod.yaml 
[root@server01 ~]# kubectl get pod
NAME   READY   STATUS    RESTARTS      AGE
box    1/1     Running   1 (16h ago)   3d19h
[root@server01 ~]# kubectl get pod box --show-labels
NAME   READY   STATUS    RESTARTS      AGE     LABELS
box    1/1     Running   1 (16h ago)   3d19h   app=as,rel=stable
~~~

过滤标签

```shell
# kubectl get pod -l app=as   # -l 后面跟要过滤的标签
# kubectl delete pod -l app=nginx   # 也可以同时删掉app=nginx的pod
# kubectl get pod -l app!=nginx   #过滤appn!=ginx表示app不是nginx的pod
# kubectl get pod -l 'app in (nginx,as)'  #过滤多个标签，in表示包含多个
# kubectl get pod -l 'app notin (nginx,as)'  #notin 表示不包含多个
# kubectl get pod -L app   #查看某个key的value值  -L：查找某个key所对应的值
```

标签的增删改查

添加标签不能每次写yaml文件，对box添加标签 env变量=生产环境

~~~shell
# kubectl label pod box env=prod   #增加标签
[root@server01 ~]# kubectl get pod --show-labels   #查询标签
NAME   READY   STATUS    RESTARTS      AGE     LABELS
box    1/1     Running   1 (16h ago)   3d19h   app=as,env=prod,rel=stable
# kubectl label pod box env=test --overwrite   #修改标签，--overwrite参数表示如果Pod已经有了这个标签，那么就覆盖原有的值。如果没有这个标签，那么就会添加一个新的标签
[root@server01 ~]# kubectl get pod --show-labels
NAME   READY   STATUS    RESTARTS      AGE     LABELS
box    1/1     Running   1 (16h ago)   3d19h   app=as,env=test,rel=stable
# kubectl label pod box env-    #删除标签，key-
NAME   READY   STATUS    RESTARTS      AGE     LABELS
box    1/1     Running   1 (16h ago)   3d19h   app=as,rel=stable
~~~

## kubernetes插件（infopod）

~~~shell
[root@server01 ~]# vim /usr/local/sbin/kubectl-infopod
#!/bin/bash
kubectl get pod -o custom-columns=NAME:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName,IMAGE:.spec.containers[0].image
或者
#!/bin/bash
show_usage() {
    echo "使用方法:"
    echo "  kubectl infopod                     # 查询当前namespace的pods"
    echo "  kubectl infopod <pod_name>          # 查询匹配的pod"
    echo "  kubectl infopod <namespace_name>    # 查询指定namespace的pods"
    echo "  kubectl infopod ... -w              # 持续监视模式"
}

query_pods() {
    local query=$1
    local watch=$2
    local namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
    local watch_flag=""
    
    if [ "$watch" = "true" ]; then
        watch_flag="-w"
    fi
    
    # 检查是否是namespace
    if echo $namespaces | grep -w -q "$query"; then
        echo "在该namespace中的pod: $query"
        kubectl get pod -n "$query" $watch_flag -o custom-columns=NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:.spec.nodeName,IMAGE:.spec.containers[0].image
    else
        # 在所有namespace中查找匹配的pod
        local found=false
        for ns in $namespaces; do
            if kubectl get pod -n "$ns" "$query" &>/dev/null; then
                echo "Pod found in namespace: $ns"
                kubectl get pod -n "$ns" "$query" $watch_flag -o custom-columns=NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:.spec.nodeName,IMAGE:.spec.containers[0].image
                found=true
                break
            fi
        done
        
        if [ "$found" = false ]; then
            echo "没有任何匹配的pod: $query"
            show_usage
        fi
    fi
}

watch_mode=false
args=()

# 解析参数
for arg in "$@"; do
    if [ "$arg" = "-w" ]; then
        watch_mode=true
    else
        args+=("$arg")
    fi
done

if [ ${#args[@]} -eq 0 ]; then
    # 无参数，查询当前namespace的pods
    kubectl get pod $([[ "$watch_mode" = true ]] && echo "-w") -o custom-columns=NAME:.metadata.name,IP:.status.podIP,STATUS:.status.phase,NODE:.spec.nodeName,IMAGE:.spec.containers[0].image
elif [ ${#args[@]} -eq 1 ]; then
    # 有一个参数，查询匹配的pod或namespace
    query_pods "${args[0]}" "$watch_mode"
else
    # 参数不正确，显示使用方法
    show_usage
    exit 1
fi

[root@server01 ~]# chmod +x /usr/local/sbin/kubectl-infopod
[root@server01 ~]# chown root:root /usr/local/sbin/kubectl-infopod
[root@server01 ~]# kubectl infopod
~~~

实验：用label标签控制pod的位置

~~~shell
[root@server01 ~]# kubectl label nodes server02 disktype=ssd
node/server02 labeled
[root@server01 ~]# kubectl label nodes server03 disktype=scsi
node/server03 labeled
[root@server01 ~]# kubectl get nodes --show-labels 
NAME       STATUS   ROLES           AGE     VERSION   LABELS
server01   Ready    control-plane   4d19h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server01,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
server02   Ready    <none>          4d19h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/arch=amd64,kubernetes.io/hostname=server02,kubernetes.io/os=linux
server03   Ready    <none>          4d19h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=scsi,kubernetes.io/arch=amd64,kubernetes.io/hostname=server03,kubernetes.io/os=linux
[root@server01 ~]# vim nginx.yaml  
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
      nodeSelector:
        disktype: ssd       #指定ssd标签
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
[root@server01 ~]# kubectl apply -f nginx.yaml 
deployment.apps/nginx-deployment created
[root@server01 ~]# kubectl infopod 
NAME                                IP              NODE       IMAGE
nginx-deployment-6b7db945b4-cglqz   10.110.225.74   server02   nginx:1.24
nginx-deployment-6b7db945b4-ffkjq   10.110.225.72   server02   nginx:1.24
nginx-deployment-6b7db945b4-wmj9s   10.110.225.73   server02   nginx:1.24
##此时标签移除，不会造成影响
[root@server01 ~]# kubectl label nodes server02 disktype-
node/server02 unlabeled
[root@server01 ~]# kubectl get nodes --show-labels 
NAME       STATUS   ROLES           AGE     VERSION   LABELS
server01   Ready    control-plane   4d20h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server01,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
server02   Ready    <none>          4d19h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server02,kubernetes.io/os=linux
server03   Ready    <none>          4d19h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=scsi,kubernetes.io/arch=amd64,kubernetes.io/hostname=server03,kubernetes.io/os=linux
[root@server01 ~]# kubectl infopod 
NAME                                IP              NODE       IMAGE
nginx-deployment-6b7db945b4-cglqz   10.110.225.74   server02   nginx:1.24
nginx-deployment-6b7db945b4-ffkjq   10.110.225.72   server02   nginx:1.24
nginx-deployment-6b7db945b4-wmj9s   10.110.225.73   server02   nginx:1.24
##迁移到其他节点
[root@server01 ~]# cat nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
      nodeSelector:
        disktype: scsi      #指定scsi标签
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
[root@server01 ~]# kubectl diff -f nginx.yaml    #查看已经部署的yaml文件，比较当前Kubernetes集群中的实际状态与nginx.yaml文件中定义的期望状态之间的差异
~~~

![image-20240727185550724](https://gitee.com/xiaojinliaqi/img/raw/master/202407271855834.png)

~~~shell
[root@server01 ~]# kubectl replace -f nginx.yaml   #替换Kubernetes集群中已存在的资源。它会读取nginx.yaml文件中定义的资源，并将其与集群中现有的同名资源进行比较。如果存在差异，它将更新现有资源以匹配nginx.yaml文件中的定义
[root@server01 ~]# kubectl infopod 
NAME                                IP              NODE       IMAGE
nginx-deployment-67c7f6c578-4cgdx   10.106.47.142   server03   nginx:1.24
nginx-deployment-67c7f6c578-b9tq8   10.106.47.141   server03   nginx:1.24
nginx-deployment-67c7f6c578-fjwkd   10.106.47.143   server03   nginx:1.24
##把节点3的标签删掉也不会受到影响
[root@server01 ~]# kubectl label nodes server03 disktype-
node/server03 unlabeled
[root@server01 ~]# kubectl infopod 
NAME                                IP              NODE       IMAGE
nginx-deployment-67c7f6c578-4cgdx   10.106.47.142   server03   nginx:1.24
nginx-deployment-67c7f6c578-b9tq8   10.106.47.141   server03   nginx:1.24
nginx-deployment-67c7f6c578-fjwkd   10.106.47.143   server03   nginx:1.24
[root@server01 ~]# kubectl get nodes --show-labels 
NAME       STATUS   ROLES           AGE     VERSION   LABELS
server01   Ready    control-plane   4d20h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server01,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
server02   Ready    <none>          4d20h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server02,kubernetes.io/os=linux
server03   Ready    <none>          4d20h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server03,kubernetes.io/os=linux 
~~~

不用标签控制，制定部署在哪个节点

~~~shell
[root@server01 ~]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
      nodeName: server02    #指定节点02
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
[root@server01 ~]# kubectl delete -f nginx.yaml   #删掉原来的部署
deployment.apps "nginx-deployment" deleted
[root@server01 ~]# kubectl apply -f nginx.yaml    #重新部署
deployment.apps/nginx-deployment created
[root@server01 ~]# kubectl infopod 
NAME                                IP              NODE       IMAGE
nginx-deployment-5cfdb9f7f7-6trrs   10.110.225.77   server02   nginx:1.24
nginx-deployment-5cfdb9f7f7-w4mx7   10.110.225.76   server02   nginx:1.24
nginx-deployment-5cfdb9f7f7-zz8pc   10.110.225.75   server02   nginx:1.24
~~~

# 标签的高级语法（污点）

## kubernetes插件(hello 查询污点)

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
~~~

~~~shell
##移除一个名为 "server01" 的 Kubernetes 节点上的污点（taint）。具体来说，它将移除名为 "node-role.kubernetes.io/control-plane" 的污点
	• kubectl: Kubernetes 的命令行工具，用于与集群进行交互。
	• taint: Kubernetes 中的一个概念，表示给节点添加一些限制条件，例如不允许某些类型的工作负载调度到该节点上。
	• node: 指定要操作的 Kubernetes 节点。
	• server01: 主节点的名称。
	• node-role.kubernetes.io/control-plane: 污点的键，表示节点的角色是控制平面节点。
	• NoSchedule: 污点的效果，表示不允许新的 Pods 被调度到这个节点上，除非它们具有相应的容忍度（toleration）。
# kubectl taint node server01 node-role.kubernetes.io/control-plane:NoSchedule-   
~~~

![image-20240727193319450](https://gitee.com/xiaojinliaqi/img/raw/master/202407271933515.png)

~~~shell
##将名为 "server01" 的 Kubernetes 节点上的 "node-role.kubernetes.io/control-plane" 污点设置为 NoSchedule，即不允许新的 Pods 被调度到这个节点上，除非它们具有相应的容忍度（toleration）
# kubectl taint node server01 node-role.kubernetes.io/control-plane="":NoSchedule

NoSchedule：没有容忍不可调度
PreferSchedule：其他节点不可调度的时候仍然接受
NoExecute：直接将pod驱离该节点
operator：
Equal：有key也有value
Exists 有key 没有value
~~~

自定义污点：给server02部署一个污点

~~~shell
# kubectl taint node server02 node-type=prod:NoSchedule   
~~~

![image-20240727195016351](https://gitee.com/xiaojinliaqi/img/raw/master/202407271950393.png)

删除并重新部署nginx.yaml文件

~~~shell
[root@server01 ~]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
~~~



kubectl infopod查看发现部署在server3上

![image-20240727194839995](https://gitee.com/xiaojinliaqi/img/raw/master/202407271948039.png)

容忍污点就可以部署

~~~shell
[root@server01 ~]# cat nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
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
      tolerations:
      - key: node-type     #这是污点的名称，表明该容忍是针对哪个污点的
        operator: Equal    #表示Pod的调度器会检查节点的污点是否等于（Equal）指定的值
        value: prod       #这是与key对应的值，Pod的调度器会查找具有node-type为prod的污点的节点
        effect: NoSchedule  #这是容忍的效应。如果一个节点有相应的污点（即node-type等于prod），那么通常这个污点会阻止没有相应容忍的Pod被调度到这个节点上。但是，如果你的Pod定义了这样的容忍，那么它就可以忽略这个污点的NoSchedule效应，可以被调度到这个节点上
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
[root@server01 ~]# kubectl apply -f nginx.yaml 
[root@server01 ~]# kubectl infopod
NAME                                IP              NODE       IMAGE
nginx-deployment-78b75989b9-2s6mj   10.106.47.153   server03   nginx:1.24
nginx-deployment-78b75989b9-7m57k   10.110.225.86   server02   nginx:1.24
nginx-deployment-78b75989b9-prssm   10.110.225.88   server02   nginx:1.24
nginx-deployment-78b75989b9-s68zs   10.110.225.87   server02   nginx:1.24
nginx-deployment-78b75989b9-vv4h4   10.106.47.152   server03   nginx:1.24
nginx-deployment-78b75989b9-z9c7v   10.106.47.151   server03   nginx:1.24
[root@server01 ~]# kubectl describe pod nginx-deployment-78b75989b9-2s6mj
~~~

![image-20240727201102289](https://gitee.com/xiaojinliaqi/img/raw/master/202407272011341.png)

修改容忍时间

~~~shell
node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
~~~

~~~shell
[root@server01 ~]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 6
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      tolerations:
      - key: node-type
        operator: Equal
        value: prod
        effect: NoSchedule
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      - key: node.kubernetes.io/unreachable
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
[root@server01 ~]# kubectl apply -f nginx.yaml
[root@server01 ~]# kubectl infopod 
NAME                                IP              NODE       IMAGE
nginx-deployment-594b8b89fb-9p52c   10.110.225.89   server02   nginx:1.24
nginx-deployment-594b8b89fb-grsmg   10.106.47.155   server03   nginx:1.24
nginx-deployment-594b8b89fb-hgjjv   10.110.225.90   server02   nginx:1.24
nginx-deployment-594b8b89fb-l442m   10.106.47.156   server03   nginx:1.24
nginx-deployment-594b8b89fb-swrhg   10.110.225.91   server02   nginx:1.24
nginx-deployment-594b8b89fb-vk9tx   10.106.47.154   server03   nginx:1.24
[root@server01 ~]# kubectl describe pod nginx-deployment-594b8b89fb-9p52c
~~~

![image-20240727201947863](https://gitee.com/xiaojinliaqi/img/raw/master/202407272019905.png)

系统污点

- node.kubernetes.io/disk-pressure:NoSchedule     op=Exists：表示如果一个节点处于磁盘压力状态，那么新的 Pods 将不会被调度到该节点上。
- node.kubernetes.io/memory-pressure:NoSchedule     op=Exists：表示如果一个节点处于内存压力状态，那么新的 Pods 将不会被调度到该节点上。
- node.kubernetes.io/network-unavailable:NoSchedule     op=Exists：表示如果一个节点的网络不可用，那么新的 Pods 将不会被调度到该节点上。
- node.kubernetes.io/not-ready:NoExecute     op=Exists：表示如果一个节点的状态为 "NotReady"，那么在该节点上运行的 Pods 将被驱逐。
- node.kubernetes.io/pid-pressure:NoSchedule     op=Exists：表示如果一个节点处于进程压力状态，那么新的 Pods 将不会被调度到该节点上。
- node.kubernetes.io/unreachable:NoExecute     op=Exists：表示如果一个节点无法访问，那么在该节点上运行的 Pods 将被驱逐。
- node.kubernetes.io/unschedulable:NoSchedule     op=Exists：表示如果一个节点被标记为不可调度，那么新的 Pods 将不会被调度到该节点上。

在server3上打个标签 node-type类型为test，立即执行

~~~shell
[root@server01 ~]# kubectl taint node server03 node-type=test:NoExecute  #立即执行
~~~

![image-20240727202820718](https://gitee.com/xiaojinliaqi/img/raw/master/202407272028781.png)

~~~shell
#最后删除即可
[root@server01 ~]# kubectl delete -f nginx.yaml
deployment.apps "nginx-deployment" deleted
[root@server01 ~]# kubectl taint node server02 node-type-
node/server02 untainted
[root@server01 ~]# kubectl taint node server03 node-type-
node/server03 untainted
[root@server01 ~]# kubectl hello 
The message show all nodes taints:
server01:
        node-role.kubernetes.io/control-plane=:NoSchedule
server02:

server03:

~~~

# 标签的高级语法（亲和）

![image-20240727203748302](https://gitee.com/xiaojinliaqi/img/raw/master/202407272037651.png)

required：亲和的方式，required是强制，perferred 是相对亲和

DuringScheduling：调度期间进行亲和

IgnoredDuringExecution：不影响已经调度的pod

 

matchLabels： 单标签语法匹配

matchExpressions： 多标签语法匹配

~~~shell
[root@server01 ~]# kubectl label nodes server02 gpu=true
node/server02 labeled
[root@server01 ~]# kubectl hello 
The message show all nodes taints:
server01:
        node-role.kubernetes.io/control-plane=:NoSchedule
server02:

server03:

[root@server01 ~]# kubectl get nodes --show-labels
NAME       STATUS   ROLES           AGE     VERSION   LABELS
server01   Ready    control-plane   4d22h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server01,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
server02   Ready    <none>          4d21h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,gpu=true,kubernetes.io/arch=amd64,kubernetes.io/hostname=server02,kubernetes.io/os=linux
server03   Ready    <none>          4d21h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server03,kubernetes.io/os=linux
~~~

把nginx强制亲和到节点02

~~~shell
[root@server01 ~]# vim nginx.yaml  
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 6
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:                #亲和性配置的顶层字段
        nodeAffinity:  #表明我们正在设置的是节点亲和性规则，这些规则会限制Pod能被调度到哪些节点上
           requiredDuringSchedulingIgnoredDuringExecution:   #在调度时必须满足，但在运行时如果节点发生变化，这些规则就不再适用
            nodeSelectorTerms:
            - matchExpressions:   #包含了节点标签的匹配表达式
              - key: gpu          #节点必须具有的标签的键    
                operator: In      #这是用于比较的操作符，表示我们要检查节点标签的值是否在某个值集合中
                values:
                - "true"           #这是一个数组，包含了我们希望节点标签的值与之匹配的值集合，在这个例子中是"true"
      tolerations:
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      - key: node.kubernetes.io/unreachable
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 30
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
[root@server01 ~]# kubectl apply -f nginx.yaml 
deployment.apps/nginx-deployment created
[root@server01 ~]# kubectl infopod 
NAME                                IP               NODE       IMAGE
nginx-deployment-8669b56687-24nql   10.110.225.100   server02   nginx:1.24
nginx-deployment-8669b56687-c26x4   10.110.225.99    server02   nginx:1.24
nginx-deployment-8669b56687-kqbmm   10.110.225.97    server02   nginx:1.24
nginx-deployment-8669b56687-r2sqs   10.110.225.95    server02   nginx:1.24
nginx-deployment-8669b56687-r52sf   10.110.225.98    server02   nginx:1.24
nginx-deployment-8669b56687-xhxhb   10.110.225.96    server02   nginx:1.24
~~~

现在希望节点数量增加

用于将名为"nginx-deployment"的Kubernetes部署中的副本数量设置为10

~~~shell
[root@server01 ~]# kubectl scale deployment nginx-deployment --replicas 10
[root@server01 ~]# kubectl infopod 
NAME                                IP               NODE       IMAGE
nginx-deployment-8669b56687-hgpl8   10.110.225.107   server02   nginx:1.24
nginx-deployment-8669b56687-jqhzf   10.110.225.110   server02   nginx:1.24
nginx-deployment-8669b56687-k5v4l   10.110.225.106   server02   nginx:1.24
nginx-deployment-8669b56687-kzpkt   10.110.225.103   server02   nginx:1.24
nginx-deployment-8669b56687-lgcjp   10.110.225.108   server02   nginx:1.24
nginx-deployment-8669b56687-mmwng   10.110.225.101   server02   nginx:1.24
nginx-deployment-8669b56687-nw5rk   10.110.225.104   server02   nginx:1.24
nginx-deployment-8669b56687-sdqgs   10.110.225.102   server02   nginx:1.24
nginx-deployment-8669b56687-skx7d   10.110.225.105   server02   nginx:1.24
nginx-deployment-8669b56687-vjkhq   10.110.225.109   server02   nginx:1.24

~~~

最后删掉即可

~~~shell
[root@server01 ~]# kubectl delete -f nginx.yaml
deployment.apps "nginx-deployment" deleted
[root@server01 ~]# kubectl label nodes server02 gpu-
node/server02 unlabeled
[root@server01 ~]# kubectl infopod 
~~~

