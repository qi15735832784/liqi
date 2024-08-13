# kubernetes健康检查的三种探针



1. ## pod必须健康

2. ## container健康

	1. ### docker ps

3. ## 容器内的service要健康

	1. ### netstate

	2. ### systemctl status

4. ## 服务文件健康

	1. ### 访问的文件cat/ls

## 健康探测：

Readiness：就绪探针，如果探测失败，则 pod 不能进入 ready 状态	

Liveness：保活探针，如果探测失败，则重启 pod 及容器

Startup：慢启动保护器，允许探测失败N次
	计算方法：failureThreshold * periodSeconds = 30 * 10
	failureThreshold：表示允许失败多少次
	periodSeconds：表示失败检测的间隔时间

## 三种探针类型：

1. Exec探针：执行进程的地方，容器的状态由进程的退出状态码决定
2. HTTP GET探针：向容器发送HTTP GET请求，通过HTTP状态码判断容器进行状态是否就绪
3. TCP socket探针：打开一个TCP连接到容器的指定端口

## 探针的最佳选择：

1. Readinrss + Exec：重要的文件或者配置丢失，则禁止对外提供服务

2. Liveness + TCP socket：表示如果服务没有启动或退出，则重启服务
3. Startup + HTTP GET：表示客户端多久能访问

### Tips:

1. 三个探针互相不冲突
2. 健康检查的主体是pod



### 滚动更新失败的原因：

1. Quota不足
2. Readiness Probe失败
3. image pull失败
4. 执行权限不足
5. Limit Ranges范围
6. 应用程序运行错误



## 第一种	Exec探针

~~~shell
[root@server01 ~]# mkdir test
[root@server01 ~]# cd test/
#探测容器不能进入readiness
[root@server01 test]# vim ready.yaml  
apiVersion: v1
kind: Pod
metadata:
  name: readiness   # 定义 Pod 的名称为 "readiness"
spec:   #定义 Pod 的规格
  containers:   #定义 Pod 中的容器
  - name: readiness   #容器名称为 "readiness"
    image: busybox:1.36   #使用 busybox:1.36 镜像
    imagePullPolicy: IfNotPresent   #仅在镜像不存在时才拉取
    args:
    - /bin/sh
    - -c
    - touch /tmp/test; sleep 30; rm -rf /tmp/test; sleep 1d   #创建 /tmp/test 文件
睡眠 30 秒，删除 /tmp/test 文件，睡眠 1 天
    readinessProbe:    #定义就绪探针
      exec:    #执行命令来检查就绪状态
        command:     #使用 cat /tmp/test 命令检查文件是否存在
        - cat  
        - /tmp/test
      initialDelaySeconds: 10    #首次检查前等待 10 秒
      periodSeconds: 5   #每 5 秒检查一次
#这个配置的目的是演示 Kubernetes 的就绪探针功能。容器启动后，会创建 /tmp/test 文件，30 秒后删除该文件。就绪探针会检查这个文件是否存在。这意味着在前 30 秒内，Pod 会被认为是就绪的，之后会变为未就绪状态。这种设置通常用于测试或演示就绪探针的行为
[root@server01 test]# kubectl apply -f read.yaml      
[root@server01 test]# kubectl describe pod readiness   
[root@server01 test]# kubectl delete -f ready.yaml
~~~

## 第二种	HTTP GET探针

~~~shell
[root@server01 test]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  revisionHistoryLimit: 10
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
        readinessProbe:
          httpGet:
            path: /
            port: 80
          periodSeconds: 1
[root@server01 test]# kubectl apply -f nginx.yaml 
[root@server01 test]# kubectl get pod
[root@server01 test]# kubectl delete -f nginx.yaml
~~~

## 第三种	TCP socket探针

~~~shell
[root@server01 test]# cat nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  revisionHistoryLimit: 10
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
        readinessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
[root@server01 test]# kubectl apply -f nginx.yaml 
deployment.apps/web created

~~~

## liveness探针实验

~~~shell
[root@server01 test]# vim liveness.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: liveness
spec:
  containers:
  - name: readiness
    image: busybox:1.36
    imagePullPolicy: IfNotPresent
    args:
    - /bin/sh
    - -c
    - touch /tmp/test; sleep 30; rm -rf /tmp/test; sleep 1d
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/test
      initialDelaySeconds: 10
      periodSeconds: 5
[root@server01 test]# kubectl apply -f liveness.yaml 
pod/liveness created
[root@server01 test]# kubectl get pod -w

~~~



~~~shell
[root@server01 test]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  revisionHistoryLimit: 10
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
        readinessProbe:
          exec:
            command:
            - cat 
            - /usr/share/nginx/html/index.html
          initialDelaySeconds: 10
          periodSeconds: 5
          successThreshold: 3
        livenessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
          timeoutSeconds: 5
        startupProbe:
          httpGet:
            path: /
            port: 80
          failureThreshold: 30
          periodSeconds: 10
[root@server01 test]# kubectl apply -f nginx.yaml
[root@server01 test]# kubectl delete -f nginx.yaml
~~~

模拟实验

~~~shell
[root@docker01 test]# vim appv1.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  revisionHistoryLimit: 10
  replicas: 10
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
        image: busybox:1.36
        imagePullPolicy: IfNotPresent
        ports:
        args:
        - /bin/sh
        - -c
        - sleep 10; touch /tmp/test; sleep 1d
        readinessProbe:
          exec:
            command:
            - cat
            - /tmp/test
          initialDelaySeconds: 15
          periodSeconds: 5

[root@docker01 test]# vim appv2.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  revisionHistoryLimit: 10
  replicas: 10
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
        image: busybox:1.36
        imagePullPolicy: IfNotPresent
        ports:
        args:
        - /bin/sh
        - -c
        - sleep 1d
        readinessProbe:
          exec:
            command:
            - cat
            - /tmp/test
          initialDelaySeconds: 15
          periodSeconds: 5
~~~

# 初始化容器

用途：

1. init(initial)容器包含一些安装过程中容器中不存在的实用工具，或者个性代码，比如mysql的初始化，客户端的连接 等等
2. 避免初始化过程中 或客户端认证过程中的加密数据被泄露
3. init 容器可以 以root身份运行，执行一些权限较高发命令
4. init 相关操作执行完毕后就会退出，不会给业务容器带来安全隐患

 ![image-20240730165410680](https://gitee.com/xiaojinliaqi/img/raw/master/202407301654836.png)

## 初始化小实验（共享文件）

~~~shell
[root@server01 test]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  revisionHistoryLimit: 10   #保留 10 个旧的 ReplicaSets 用于回滚
  replicas: 3   #指定运行 3 个副本
  selector:   #选择标签为 app: nginx 的 Pod
    matchLabels:
      app: nginx
  template:   #定义 Pod 模板
    metadata:
      labels:
        app: nginx   #为 Pod 设置标签 app: nginx
    spec:
      initContainers:   #定义初始化容器
      - name: init-touch
        image: busybox:1.36   #使用 busybox:1.36 镜像
        imagePullPolicy: IfNotPresent
        command:
        - sh 
        - -c
        - touch /mnt/test-init.txt   #创建一个文件
        volumeMounts:
        - name: data
          mountPath: /mnt   #挂载名为 "data" 的卷到 /mnt 目录
      containers:   #定义主容器
      - name: nginx
        image: nginx:1.24   #使用 nginx:1.24 镜像
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80   #80 端口
        volumeMounts:
        - name: data
          mountPath: /mnt   #同样挂载 "data" 卷到 /mnt 目录
      volumes:   #定义卷
      - name: data
        emptyDir: {}   #创建一个名为 "data" 的 emptyDir 卷
#以上配置的主要目的是：部署一个 nginx 服务，运行 3 个副本。使用初始化容器在共享卷中创建一个文件。主容器（nginx）可以访问这个共享卷。
[root@server01 test]# kubectl apply -f nginx.yaml
[root@server01 test]# kubectl get pod
NAME                   READY   STATUS    RESTARTS   AGE
web-855696c8d4-bxbh5   1/1     Running   0          11s
web-855696c8d4-lkrtt   1/1     Running   0          11s
web-855696c8d4-m9j9r   1/1     Running   0          11s
[root@server01 test]# kubectl exec -it web-855696c8d4-bxbh5 -- bash
Defaulted container "nginx" out of: nginx, init-touch (init)
root@web-855696c8d4-bxbh5:/# ls
bin   docker-entrypoint.d   home   media  proc  sbin  tmp
boot  docker-entrypoint.sh  lib    mnt    root  srv   usr
dev   etc                   lib64  opt    run   sys   var
root@web-855696c8d4-bxbh5:/# cd mnt/
root@web-855696c8d4-bxbh5:/mnt# ls
test-init.txt

[root@server01 test]# kubectl delete -f nginx.yaml
~~~

## 共享进程

~~~shell
[root@server01 test]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  revisionHistoryLimit: 10
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      shareProcessNamespace: true
      terminationGracePeriodSeconds: 0
      initContainers:
      - name: init-touch
        image: busybox:1.36
        imagePullPolicy: IfNotPresent
        command:
        - sh
        - -c
        - touch /mnt/test-init.txt
        volumeMounts:
        - name: data
          mountPath: /mnt
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: data
          mountPath: /mnt
      - name: box
        image: busybox:1.36
        imagePullPolicy: IfNotPresent
        command:
        - /bin/sh
        - -c
        - sleep 1d
      volumes:
      - name: data
        emptyDir: {}
[root@server01 test]# kubectl apply -f nginx.yaml
[root@server01 test]# kubectl get pod
NAME                   READY   STATUS    RESTARTS   AGE
web-6c976cff7c-bxvv7   2/2     Running   0          68s
web-6c976cff7c-g95xp   2/2     Running   0          68s
web-6c976cff7c-wkgjw   2/2     Running   0          68s
#在busybox里面可以看到nginx的进程
[root@server01 test]# kubectl exec -it pod/web-6c976cff7c-bxvv7 -c box -- sh
/ # 
/ # ps
PID   USER     TIME  COMMAND
    1 65535     0:00 /pause
   12 root      0:00 nginx: master process nginx -g daemon off;
   39 101       0:00 nginx: worker process
   40 101       0:00 nginx: worker process
   41 101       0:00 nginx: worker process
   42 101       0:00 nginx: worker process
   43 root      0:00 /bin/sh -c sleep 1d
   48 root      0:00 sh
   54 root      0:00 ps
/ # exit
[root@server01 test]# kubectl delete -f nginx.yaml 
~~~

## 临时容器

唯一的功能就是通过临时容器增加指令

~~~shell
[root@server01 test]# vim app1.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  revisionHistoryLimit: 10
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
[root@server01 test]# kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
web-8588484f4-b6nd8   1/1     Running   0          4s
web-8588484f4-k9d88   1/1     Running   0          4s
web-8588484f4-rqs6w   1/1     Running   0          4s
[root@server01 test]# kubectl debug -it web-8588484f4-b6nd8 --image busybox:1.36
/ # ip a
    inet 10.106.47.155/32 scope global eth0
/ # wget 10.106.47.155
Connecting to 10.106.47.155 (10.106.47.155:80)
saving to 'index.html'
index.html           100% |***********************************|   615  0:00:00 ETA
'index.html' saved
/ # 
/ # cat index.html 
/ # netstat -anput | grep 80
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      -
tcp        0      0 10.106.47.155:80        10.106.47.155:43118     TIME_WAIT   -
tcp        0      0 :::80                   :::*                    LISTEN      -
~~~

lifecycle容器的生命周期：
与初始化容器的区别是：先运行容器，再执行
PostStart：容器创建成功后，运行前的任务，通常可以是资源部署或初始化
PreStop：容器终止前的任务，用于优雅关闭程序/发出通知等

## 容器和宿主机共享

~~~shell
[root@server01 test]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: box1
  labels:
    app: guestbook
spec:
  containers:
  - name: test1
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
    lifecycle:
      postStart:
        exec:
          command: ["/bin/bash","-c","echo hello from poststart > /usr/share/nginx/html/hello.html"]
      preStop:
        exec:
          command: ["/bin/bash","-c","echo goodbye from prestop > /usr/share/nginx/html/goodbye.html"]
    volumeMounts:
    - name: message
      mountPath: /usr/share/nginx/html/
  volumes:
  - name: message
    hostPath:
      path: /mnt/
[root@server01 test]# kubectl apply -f pod.yaml 
[root@server01 test]# kubectl infopod 
NAME   IP              NODE       IMAGE
box1   10.110.225.97   server02   nginx:1.24
[root@server01 test]# curl 10.110.225.97/hello.html
hello from poststart
##去从节点02上
[root@server02 ~]# cd /mnt/
[root@server02 mnt]# ls
hello.html
[root@server02 mnt]# cat hello.html 
hello from poststart
##主节点上删除pod.yaml
[root@server01 test]# kubectl delete -f pod.yaml 
pod "box1" deleted
##从节点02上就会显示另外一个网页
[root@server02 mnt]# ls
goodbye.html  hello.html
[root@server02 mnt]# cat goodbye.html 
goodbye from prestop
~~~

# Daemonset

客户端：daemonset
服务端：rc/rs/depioyment/statefulset

## daemonset：

1. 保证每个节点上只有一个 pod
2. 动态标签识别
3. 滚动更新/手动更新

[github网址](https://github.com/google/cadvisor "https://github.com/google/cadvisor")

~~~shell
VERSION=v0.49.1 # use the latest release version from https://github.com/google/cadvisor/releases
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:$VERSION
~~~

三台节点都需要

~~~shell
1. 登录阿里云Docker Registry
$ docker login --username=aliyun3894322220 registry.cn-zhangjiakou.aliyuncs.com
2. 从Registry中拉取镜像
$ docker pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:[镜像版本号]

[root@server01 ~]# nerdctl login --username=aliyun3894322220 registry.cn-zhangjiakou.aliyuncs.com
##如果登错私有仓库
[root@server01 ~]# nerdctl logout
[root@server01 ~]# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1
~~~

### 每个节点只有一个pod

~~~shell
[root@server01 ~]# vim cadvisor.yaml 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
spec:
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
    spec:
      hostNetwork: true
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: cadvisor
        image: registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: rootfs
          mountPath: /roofs
          readOnly: true
        - name: sys
          mountPath: /sys
          readOnly: true
        - name: containerd
          mountPath: /var/lib/containerd/
          readOnly: true
        - name: disk
          mountPath: /dev/disk
          readOnly: true
      volumes:
      - name: rootfs
        hostPath:
          path: /
      - name: sys
        hostPath:
          path: /sys
      - name: containerd
        hostPath:
          path: /var/lib/containerd/
      - name: disk
        hostPath:
          path: /dev/disk
[root@server01 ~]# kubectl apply -f cadvisor.yaml
[root@server01 ~]# kubectl get pod
NAME             READY   STATUS    RESTARTS   AGE
cadvisor-fn4q5   1/1     Running   0          55s
cadvisor-kbbpb   1/1     Running   0          55s
cadvisor-mtsl6   1/1     Running   0          55s
[root@server01 ~]# kubectl get pod -o wide 
NAME             READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
cadvisor-fn4q5   1/1     Running   0          63s   10.15.200.13   server03   <none>           <none>
cadvisor-kbbpb   1/1     Running   0          63s   10.15.200.11   server01   <none>           <none>
cadvisor-mtsl6   1/1     Running   0          63s   10.15.200.12   server02   <none>           <none>
~~~





访问浏览器10.15.200.11:8080

![image-20240730191954487](https://gitee.com/xiaojinliaqi/img/raw/master/202407301919600.png)

### 选标签（动态标签识别）

~~~shell
[root@server01 ~]# cat cadvisor.yaml 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
spec:
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
    spec:
      nodeSelector:      #添加标签
        disk: ssd
      hostNetwork: true
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: cadvisor
        image: registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: rootfs
          mountPath: /roofs
          readOnly: true
        - name: sys
          mountPath: /sys
          readOnly: true
        - name: containerd
          mountPath: /var/lib/containerd/
          readOnly: true
        - name: disk
          mountPath: /dev/disk
          readOnly: true
      volumes:
      - name: rootfs
        hostPath:
          path: /
      - name: sys
        hostPath:
          path: /sys
      - name: containerd
        hostPath:
          path: /var/lib/containerd/
      - name: disk
        hostPath:
          path: /dev/disk
[root@server01 ~]# kubectl apply -f cadvisor.yaml 
daemonset.apps/cadvisor created
#第二次部署完成之后，没有节点
[root@server01 ~]# kubectl get pod
No resources found in default namespace.
#添加节点在server03上部署，添加标签
[root@server01 ~]# kubectl label nodes server03 disk=ssd
node/server03 labeled
[root@server01 ~]# kubectl get pod
NAME             READY   STATUS    RESTARTS   AGE
cadvisor-dvx24   1/1     Running   0          5s
[root@server01 ~]# kubectl infopod 
NAME             IP             NODE       IMAGE
cadvisor-dvx24   10.15.200.13   server03   registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1
#给主节点上部署，添加标签即可
[root@server01 ~]# kubectl label nodes server01 disk=ssd
node/server01 labeled
[root@server01 ~]# kubectl infopod 
NAME             IP             NODE       IMAGE
cadvisor-dvx24   10.15.200.13   server03   registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1
cadvisor-msn9j   10.15.200.11   server01   registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1
#要是删掉server03上的标签，就不会在03上部署
[root@server01 ~]# kubectl label nodes server03 disk-
node/server03 unlabeled
[root@server01 ~]# kubectl infopod 
NAME             IP             NODE       IMAGE
cadvisor-msn9j   10.15.200.11   server01   registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1
~~~

### 滚动更新/手动更新（滚动）

~~~shell
[root@server01 ~]# vim cadvisor.yaml 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: cadvisor
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
[root@server01 ~]# kubectl apply -f cadvisor.yaml 
[root@server01 ~]# kubectl infopod 
NAME             IP              NODE       IMAGE
cadvisor-4w862   10.105.199.7    server01   nginx:1.24
cadvisor-brd2j   10.110.225.98   server02   nginx:1.24
cadvisor-n8pv8   10.106.47.158   server03   nginx:1.24
[root@server01 ~]# kubectl edit daemonsets.apps cadvisor 
/输入image 找到1.24修改为1.22
[root@server01 ~]# kubectl infopod 
NAME             IP              NODE       IMAGE
cadvisor-ctqtw   10.106.47.159   server03   nginx:1.22
cadvisor-m4jr9   10.105.199.8    server01   nginx:1.22
cadvisor-r9k87   10.110.225.99   server02   nginx:1.22
~~~

### 滚动更新/手动更新（手动）

~~~shell
[root@server01 ~]# vim cadvisor.yaml 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
spec:
  updateStrategy:
    type: OnDelete 
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: cadvisor
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
[root@server01 ~]# kubectl apply -f cadvisor.yaml 
[root@server01 ~]# kubectl infopod 
NAME             IP               NODE       IMAGE
cadvisor-dwcr7   10.106.47.161    server03   nginx:1.24
cadvisor-g5hk4   10.105.199.10    server01   nginx:1.24
cadvisor-pw7xb   10.110.225.101   server02   nginx:1.24
[root@server01 ~]# kubectl edit daemonsets.apps cadvisor 
/输入image 找到1.24修改为latest，发现改不成功再试一次
error: daemonsets.apps "cadvisor" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-3981737636.yaml"
error: Edit cancelled, no valid changes were saved.
[root@server01 ~]# kubectl edit daemonsets.apps cadvisor 
daemonset.apps/cadvisor edited
#infopod查出来和之前一样
[root@server01 ~]# kubectl infopod 
NAME             IP               NODE       IMAGE
cadvisor-dwcr7   10.106.47.161    server03   nginx:1.24
cadvisor-g5hk4   10.105.199.10    server01   nginx:1.24
cadvisor-pw7xb   10.110.225.101   server02   nginx:1.24
#手动删掉，等等会自己出
[root@server01 ~]# kubectl delete pod cadvisor-dwcr7 
pod "cadvisor-dwcr7" deleted
[root@server01 ~]# kubectl infopod 
NAME             IP               NODE       IMAGE
cadvisor-g5hk4   10.105.199.10    server01   nginx:1.24
cadvisor-jxg9l   <none>           server03   nginx:latest
cadvisor-pw7xb   10.110.225.101   server02   nginx:1.24
[root@server01 ~]# kubectl infopod 
NAME             IP               NODE       IMAGE
cadvisor-g5hk4   10.105.199.10    server01   nginx:1.24
cadvisor-jxg9l   10.106.47.162    server03   nginx:latest
cadvisor-pw7xb   10.110.225.101   server02   nginx:1.24
[root@server01 ~]# kubectl rollout undo daemonset cadvisor   #恢复到它之前的状态
[root@server01 ~]# kubectl infopod 
NAME             IP               NODE       IMAGE
cadvisor-g5hk4   10.105.199.10    server01   nginx:1.24
cadvisor-jxg9l   10.106.47.162    server03   nginx:latest
cadvisor-pw7xb   10.110.225.101   server02   nginx:1.24
[root@server01 ~]# kubectl delete -f cadvisor.yaml 
daemonset.apps "cadvisor" deleted
~~~



# 课后作业

## 1.使用初始化容器创建 https 的证书和密钥, 使用 deployment 部署 nginx:latest 副本 3 个, 并且启动 https 的访问.

## 2.使用 poststart, 创建 index.html 页面内容为: poststart good.

~~~shell
[root@server01 ~]# mkdir https
[root@server01 ~]# cd https/
[root@server01 https]# kubectl get pod
No resources found in default namespace.
[root@server01 https]# vim alpine.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-https
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
      initContainers:
      - name: init-ssl
        image: alpine:latest
        command: ["/bin/sh", "-c"]
        args:
          - |
            apk add --no-cache openssl &&
            mkdir -p /etc/nginx/ssl &&
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
              -keyout /etc/nginx/ssl/tls.key \
              -out /etc/nginx/ssl/tls.crt \
              -subj "/C=CN/ST=Beijing/L=Beijing/O=MyCompany/CN=mydomain.com";
        volumeMounts:
        - name: ssl-volume
          mountPath: /etc/nginx/ssl
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 443
        volumeMounts:
        - name: ssl-volume
          mountPath: /etc/nginx/ssl
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "echo 'poststart good' > /usr/share/nginx/html/index.html"]
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo 'server {
                listen 443 ssl;
                server_name mydomain.com;
                ssl_certificate /etc/nginx/ssl/tls.crt;
                ssl_certificate_key /etc/nginx/ssl/tls.key;
                location / {
                    root   /usr/share/nginx/html;
                    index  index.html index.htm;
                }
                ssl_protocols       TLSv1.2 TLSv1.3;
                ssl_ciphers         HIGH:!aNULL:!MD5;
            }' > /etc/nginx/conf.d/default.conf && \
            nginx -g 'daemon off;'
      volumes:
      - name: ssl-volume
        emptyDir: {}
[root@server01 https]# kubectl apply -f alpine.yaml 
deployment.apps/nginx-https created
[root@server01 https]# kubectl infopod 
NAME                           IP               NODE       IMAGE
nginx-https-545fc557f7-8glkc   10.106.47.163    server03   nginx:latest
nginx-https-545fc557f7-9zll2   10.110.225.103   server02   nginx:latest
nginx-https-545fc557f7-pmp5n   10.110.225.102   server02   nginx:latest
[root@server01 https]# curl -k https://10.106.47.163
poststart good
[root@server01 https]# kubectl describe pods nginx-https-545fc557f7-8glkc 
    Mounts:
      /etc/nginx/ssl from ssl-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-v785s (ro)
~~~

### 验证访问：curl -k https://10.106.47.163

![image-20240730215838341](https://gitee.com/xiaojinliaqi/img/raw/master/202407302158427.png)

### 查看挂载卷：kubectl describe pods nginx-https-545fc557f7-8glkc

![image-20240730220108438](https://gitee.com/xiaojinliaqi/img/raw/master/202407302201482.png)

## 3.使用 daemonset 部署 cadvisor 和 node-exporter 在所有的节点, 且不可被驱离.

~~~shell
# 拉取镜像（三台都需要）
[root@server01 https]# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/node-exporter:v1.8.1
[root@server01 https]# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1
# 更改标签，不更改时下面yaml文件中需要更改镜像名（三台都需要）
[root@server01 https]# nerdctl --namespace k8s.io tag registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/node-exporter:v1.8.1 node-exporter:v1.8.1
[root@server01 https]# nerdctl --namespace k8s.io tag registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/cadvisor:v0.49.1 cadvisor:v0.49.1
# 创建cadvisor.yaml文件
[root@server01 https]# vim cadvisor.yaml 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Equal
          effect: NoSchedule
        - key: node.kubernetes.io/disk-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/memory-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/network-unavailable
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/pid-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unschedulable
          operator: Exists
          effect: NoSchedule
      hostPID: true
      containers:
      - name: node-exporter
        image: node-exporter:v1.8.1
        args:
        - --path.procfs=/host/proc
        - --path.sysfs=/host/sys
        - --collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)
        ports:
        - containerPort: 9100
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
spec:
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
    spec:
      hostNetwork: true
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Equal
          effect: NoSchedule
        - key: node.kubernetes.io/disk-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/memory-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/network-unavailable
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/pid-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unschedulable
          operator: Exists
          effect: NoSchedule
      containers:
        - name: cadvisor
          image: cadvisor:v0.49.1
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: rootfs
              mountPath: /rootfs
              readOnly: true
            - name: sys
              mountPath: /sys
              readOnly: true
            - name: containerd
              mountPath: /var/lib/containerd/
              readOnly: true
            - name: disk
              mountPath: /dev/disk
              readOnly: true
      volumes:
        - name: rootfs
          hostPath:
            path: /
        - name: sys
          hostPath:
            path: /sys
        - name: containerd
          hostPath:
            path: /var/lib/containerd/
        - name: disk
          hostPath:
            path: /dev/disk
# 部署
kubectl apply -f cadvisor.yaml
# 查看pod节点，是否一个节点一个pod
kubectl get pods -o wide
~~~

![image-20240730221208695](https://gitee.com/xiaojinliaqi/img/raw/master/202407302212749.png)

### 浏览器分别访问8080以及9100端口

![image-20240730221410419](https://gitee.com/xiaojinliaqi/img/raw/master/202407302214505.png)

![image-20240730221432991](https://gitee.com/xiaojinliaqi/img/raw/master/202407302214054.png)

### 将kube02,kube03关机，验证是否无法被驱离

![img](https://gitee.com/xiaojinliaqi/img/raw/master/202407302215542.png)

节点未发生变化，证明无法被驱离

## 4.使用 deployment 部署 Prometheus 服务端 和 grafana 副本各 1 个

~~~shell
# 拉取镜像
[root@server01 https]# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/grafana:11.0.0
[root@server01 https]# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/prometheus:v2.53.0
# 更改标签，不更改时下面yaml文件中需要更改镜像名
[root@server01 https]# nerdctl --namespace k8s.io tag registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/prometheus:v2.53.0 prometheus:v2.53.0
[root@server01 https]# nerdctl --namespace k8s.io tag registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/grafana:11.0.0 grafana:11.
# 创建配置文件，改主机名和IP地址
[root@server01 https]# cat kan.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      hostNetwork: true
      securityContext:
        fsGroup: 65534
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Equal
          effect: NoSchedule
        - key: node.kubernetes.io/disk-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/memory-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/network-unavailable
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/pid-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unschedulable
          operator: Exists
          effect: NoSchedule
      nodeSelector:
        kubernetes.io/hostname: server01
      initContainers:
        - name: init-config
          image: busybox
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "global:
                scrape_interval:     15s
                evaluation_interval: 15s
                external_labels:
                  monitor: 'codelab-monitor'
              rule_files:
                - 'prometheus.rules.yml'
              scrape_configs:
                - job_name: 'prometheus'
                  static_configs:
                    - targets: ['10.15.200.11:9091','10.15.200.11:9100','10.15.200.11:8080','10.15.200.12:9100','10.15.200.12:8080','10.15.200.13:9100','10.15.200.13:8080']" > /etc/prometheus/prometheus.yml
          volumeMounts:
            - name: config
              mountPath: /etc/prometheus
      containers:
        - name: prometheus
          image: prom/prometheus:v2.53.0
          args:
            - "--config.file=/etc/prometheus/prometheus.yml"
            - "--storage.tsdb.path=/prometheus"
            - "--web.listen-address=:9091"
            - "--web.enable-lifecycle"
            - "--storage.tsdb.no-lockfile"
          ports:
            - containerPort: 9091
          volumeMounts:
            - name: config
              mountPath: /etc/prometheus
            - name: storage
              mountPath: /prometheus
      volumes:
        - name: config
          emptyDir: {}
        - name: storage
          emptyDir:
            sizeLimit: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  labels:
    app: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      hostNetwork: true
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Equal
          effect: NoSchedule
        - key: node.kubernetes.io/disk-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/memory-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/network-unavailable
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/pid-pressure
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoSchedule
        - key: node.kubernetes.io/unschedulable
          operator: Exists
          effect: NoSchedule
      nodeSelector:
        kubernetes.io/hostname: server01
      containers:
        - name: grafana
          image: grafana:11.0.0
          ports:
            - containerPort: 3000
          env:
            - name: GF_SECURITY_ADMIN_PASSWORD
              value: "123.com"
# 部署
kubectl apply -f kan.yaml
# 查看pod部署情况
kubectl get pods
~~~

![image-20240730222036908](https://gitee.com/xiaojinliaqi/img/raw/master/202407302220960.png)

### 浏览器验证 访问Prometheus（端口号9091）

![image-20240730222253019](https://gitee.com/xiaojinliaqi/img/raw/master/202407302222097.png)

## 5.在 node1 上访问 grafana 页面可以查看容器和主机状态.

访问Grafana（端口号3000）

![image-20240730222444984](https://gitee.com/xiaojinliaqi/img/raw/master/202407302224325.png)
