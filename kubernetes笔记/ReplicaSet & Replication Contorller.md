#   ReplicaSet & Replication Contorller

~~~test
ReplicaSet和Replication Controller都是Kubernetes中用于管理Pod副本的组件。

ReplicaSet是Kubernetes中的一个API对象，它定义了一组Pod副本的数量和标签选择器。当ReplicaSet被创建时，它会确保指定数量的Pod副本始终处于运行状态。如果某个Pod失败或被删除，ReplicaSet会自动创建新的Pod来替换它，以保持指定的副本数量。

Replication Controller（简称RC）是Kubernetes早期版本中的一个核心概念，用于控制Pod副本的数量。与ReplicaSet类似，它通过标签选择器来识别要管理的Pod，并确保它们的数量始终满足预期。然而，在较新的Kubernetes版本中，Replication Controller已经被弃用，推荐使用ReplicaSet来代替。

总结起来，ReplicaSet和Replication Controller都用于确保一组Pod副本的数量和可用性，但Replication Controller已经被弃用，推荐使用ReplicaSet。
~~~

![image-20240729164317461](https://gitee.com/xiaojinliaqi/img/raw/master/202407291643730.png)

## 举例Rc的

~~~shell
[root@server01 ~]# vim rc.yaml    #编辑单标签
apiVersion: v1
kind: ReplicationController
metadata:
  name: rc-test
spec:
  replicas: 3
  selector:
    app: rcpod
  template:
    metadata:
      labels:
        app: rcpod
    spec:
      containers:
      - name: rctest
        image: httpd:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
[root@server01 ~]# kubectl apply -f rc.yaml 
[root@server01 ~]# kubectl get pod
NAME            READY   STATUS    RESTARTS   AGE
rc-test-g9xmb   1/1     Running   0          28s
rc-test-h94nz   1/1     Running   0          28s
rc-test-ht866   1/1     Running   0          28s
[root@server01 ~]# kubectl infopod 
NAME            IP              NODE       IMAGE
rc-test-g9xmb   10.110.225.66   server02   httpd:latest
rc-test-h94nz   10.106.47.129   server03   httpd:latest
rc-test-ht866   10.110.225.65   server02   httpd:latest
[root@server01 ~]# kubectl get rc
NAME      DESIRED   CURRENT   READY   AGE
rc-test   3         3         3       74s
##有期望值，所以删除不掉
[root@server01 ~]# kubectl infopod 
NAME            IP              NODE       IMAGE
rc-test-g9xmb   10.110.225.66   server02   httpd:latest
rc-test-h94nz   10.106.47.129   server03   httpd:latest
rc-test-ht866   10.110.225.65   server02   httpd:latest
[root@server01 ~]# kubectl delete pod rc-test-g9xmb
pod "rc-test-g9xmb" deleted
[root@server01 ~]# kubectl infopod 
NAME            IP              NODE       IMAGE
rc-test-d85ll   10.106.47.130   server03   httpd:latest
rc-test-h94nz   10.106.47.129   server03   httpd:latest
rc-test-ht866   10.110.225.65   server02   httpd:latest
##查看名为 "rc-test-d85ll" 的 Kubernetes Replication Controller（RC）的详细信息
[root@server01 ~]# kubectl describe pod rc rc-test-d85ll   
Controlled By:  ReplicationController/rc-test
~~~

![image-20240729170044118](https://gitee.com/xiaojinliaqi/img/raw/master/202407291700184.png)

或者使用

~~~shell
##获取名为 "rc-test-d85ll" 的 Kubernetes pod 的详细信息，并以 YAML 格式输出
[root@server01 ~]# kubectl get pod rc-test-d85ll -o yaml
~~~

![image-20240729170356221](https://gitee.com/xiaojinliaqi/img/raw/master/202407291703287.png)

### 如果想删掉标签或者修改标签，就会自动换标签

~~~shell
[root@server01 ~]# kubectl get pod --show-labels
NAME            READY   STATUS    RESTARTS   AGE   LABELS
rc-test-d85ll   1/1     Running   0          13m   app=rcpod
rc-test-h94nz   1/1     Running   0          16m   app=rcpod
rc-test-ht866   1/1     Running   0          16m   app=rcpod
[root@server01 ~]# kubectl label pod rc-test-d85ll app=test --overwrite 
pod/rc-test-d85ll labeled
[root@server01 ~]# kubectl get pod --show-labels
NAME            READY   STATUS    RESTARTS   AGE   LABELS
rc-test-d85ll   1/1     Running   0          15m   app=test
rc-test-h94nz   1/1     Running   0          18m   app=rcpod
rc-test-ht866   1/1     Running   0          18m   app=rcpod
rc-test-shfjs   1/1     Running   0          3s    app=rcpod
##查询出来就没有显示控制者是谁，也就没有Controlled By:  ReplicationController/rc-test
[root@server01 ~]# kubectl describe pod rc-test-d85ll
~~~

### 如果增加一个标签，多一个标签，不会改变原来的标签

~~~shell
[root@server01 ~]# kubectl get pod --show-labels
NAME            READY   STATUS    RESTARTS   AGE     LABELS
rc-test-d85ll   1/1     Running   0          19m     app=test
rc-test-h94nz   1/1     Running   0          22m     app=rcpod
rc-test-ht866   1/1     Running   0          22m     app=rcpod
rc-test-shfjs   1/1     Running   0          4m33s   app=rcpod
[root@server01 ~]# kubectl label pod rc-test-shfjs env=prod
pod/rc-test-shfjs labeled
[root@server01 ~]# kubectl get pod --show-labels   #只要有原来控制器的标签就不会变化
NAME            READY   STATUS    RESTARTS   AGE     LABELS
rc-test-d85ll   1/1     Running   0          21m     app=test
rc-test-h94nz   1/1     Running   0          24m     app=rcpod
rc-test-ht866   1/1     Running   0          24m     app=rcpod
rc-test-shfjs   1/1     Running   0          6m10s   app=rcpod,env=prod
##最终删掉即可
[root@server01 ~]# kubectl delete -f rc.yaml --force --grace-period 0
[root@server01 ~]# kubectl delete pod rc-test-d85ll 
pod "rc-test-d85ll" deleted
~~~

## 举例RS的

~~~shell
[root@server01 ~]# vim rs.yaml 
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs-test
  labels:
    app: guestbook
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rspod
  template:
    metadata:
      labels:
        app: rspod
    spec:
      containers:
      - name: rctest
        image: httpd:latest
        imagePullPolicy: IfNotPresent
        ports:
          - containerPort: 80
[root@server01 ~]# kubectl apply -f rs.yaml
[root@server01 ~]# kubectl get rs
NAME      DESIRED   CURRENT   READY   AGE
rs-test   3         3         3       3m28s
[root@server01 ~]# kubectl get pod
NAME            READY   STATUS    RESTARTS   AGE
rs-test-6ts25   1/1     Running   0          5m45s
rs-test-bpq7c   1/1     Running   0          5m45s
rs-test-gckpv   1/1     Running   0          5m45s
##查询控制器
[root@server01 ~]# kubectl describe pod rs-test-6ts25 
Controlled By:  ReplicaSet/rs-test
~~~

![image-20240729173837352](https://gitee.com/xiaojinliaqi/img/raw/master/202407291738424.png)

或者使用

~~~shell
[root@server01 ~]# kubectl get pod rs-test-6ts25 -o yaml
~~~

![image-20240729174430896](https://gitee.com/xiaojinliaqi/img/raw/master/202407291744950.png)

## 演示实验

~~~shell
[root@server01 ~]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: box1
  labels:
    app: rspod
spec:
  containers:
  - name: test1
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: box2
  labels:
    app: rspod
spec:
  containers:
  - name: test2
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
[root@server01 ~]# kubectl apply -f pod.yaml 
pod/box1 created
pod/box2 created
~~~

开一个终端查询（查询出来不能部署）

~~~shell
[root@server01 ~]# kubectl get pod --watch
~~~

![image-20240729175452727](https://gitee.com/xiaojinliaqi/img/raw/master/202407291754766.png)

获取 Kubernetes 集群中所有事件，并通过 grep 命令筛选出包含 "box2" 关键字的事件。要执行此命令，您需要在已经安装并配置了 kubectl 的环境中运行它

~~~shell
[root@server01 ~]# kubectl get events | grep box2
~~~

![image-20240729175705204](https://gitee.com/xiaojinliaqi/img/raw/master/202407291757229.png)

反过来部署，先部署pod ，再部署Rs

~~~shell
[root@server01 ~]# kubectl delete -f rs.yaml --force --grace-period 0
[root@server01 ~]# kubectl get pod
No resources found in default namespace.
[root@server01 ~]# kubectl apply -f pod.yaml 
pod/box1 created
pod/box2 created
[root@server01 ~]# kubectl get pod
NAME   READY   STATUS    RESTARTS   AGE
box1   1/1     Running   0          33s
box2   1/1     Running   0          33s
[root@server01 ~]# kubectl apply -f rs.yaml      #再部署Rs
replicaset.apps/rs-test created
[root@server01 ~]# kubectl get rs 
NAME      DESIRED   CURRENT   READY   AGE
rs-test   3         3         3       24s
[root@server01 ~]# kubectl get pod
NAME            READY   STATUS    RESTARTS   AGE
box1            1/1     Running   0          100s
box2            1/1     Running   0          100s
rs-test-jn86g   1/1     Running   0          28s
[root@server01 ~]# kubectl get pod --show-labels
NAME            READY   STATUS    RESTARTS   AGE     LABELS
box1            1/1     Running   0          5m43s   app=rspod
box2            1/1     Running   0          5m43s   app=rspod
rs-test-jn86g   1/1     Running   0          4m31s   app=rspod
~~~

#为什么只部署了一个Rs？(下图在开的另外一个终端上)

期望值够了，标签上限3个，box1,box2已占用两个，所以只能部署一个Rs

![image-20240729180410132](https://gitee.com/xiaojinliaqi/img/raw/master/202407291804169.png)

刚在部署的Rs接受了这上面两个pod的管理

![image-20240729181010336](https://gitee.com/xiaojinliaqi/img/raw/master/202407291810389.png)

~~~shell
[root@server01 ~]# kubectl infopod 
NAME            IP              NODE       IMAGE
box1            10.106.47.132   server03   nginx:1.24
box2            10.110.225.70   server02   nginx:1.24
rs-test-jn86g   10.106.47.133   server03   httpd:latest
#删掉一个pod
[root@server01 ~]# kubectl delete pod box1
[root@server01 ~]# kubectl infopod 
NAME            IP              NODE       IMAGE
box2            10.110.225.70   server02   nginx:1.24
rs-test-jn86g   10.106.47.133   server03   httpd:latest
rs-test-zzjhx   10.110.225.71   server02   httpd:latest
#期望值是指labels标签的数量
删除Rs pod就全删了
[root@server01 ~]# kubectl delete rs rs-test 
replicaset.apps "rs-test" deleted
[root@server01 ~]# kubectl get pod
No resources found in default namespace.
~~~

### 如果数量不足的时候（把rs的副本数量改为1）

~~~shell
[root@server01 ~]# kubectl apply -f pod.yaml 
pod/box1 created
pod/box2 created
[root@server01 ~]# kubectl get pod
NAME   READY   STATUS    RESTARTS   AGE
box1   1/1     Running   0          11s
box2   1/1     Running   0          11s
[root@server01 ~]# vim rs.yaml 
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs-test
  labels:
    app: guestbook
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rspod
  template:
    metadata:
      labels:
        app: rspod
    spec:
      containers:
      - name: rctest
        image: httpd:latest
        imagePullPolicy: IfNotPresent
        ports:
          - containerPort: 80
[root@server01 ~]# kubectl apply -f rs.yaml 
replicaset.apps/rs-test created
[root@server01 ~]# kubectl get pod
NAME   READY   STATUS    RESTARTS   AGE
box2   1/1     Running   0          3m25s    #会随机删除
##pod和副本的数量指代这是标签的数量，期望值也好，管理者也好，只看标签
~~~

Rs的特性：多标签

~~~shell
[root@server01 ~]# vim rs.yaml 
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs-test
  labels:
    app: guestbook
    tier: frontend
spec:
  replicas: 5
  selector:
    matchExpressions:
    - {key: tier, operator: In, values: [frontend, canary]}
    - {key: app, operator: In, values: [guestbook, test]}
  template:
    metadata:
      labels:
        app: test
        tier: canary
    spec:
      containers:
      - name: rctest
        image: httpd:latest
        imagePullPolicy: IfNotPresent
[root@server01 ~]# kubectl apply -f rs.yaml
[root@server01 ~]# kubectl get pod --show-labels
NAME            READY   STATUS    RESTARTS   AGE   LABELS
rs-test-47w2f   1/1     Running   0          56s   app=test,tier=canary
rs-test-6xxxx   1/1     Running   0          56s   app=test,tier=canary
rs-test-l9pgt   1/1     Running   0          56s   app=test,tier=canary
rs-test-q9j4m   1/1     Running   0          56s   app=test,tier=canary
rs-test-qxr9l   1/1     Running   0          56s   app=test,tier=canary
[root@server01 ~]# vim pod.yaml 
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
---
apiVersion: v1
kind: Pod
metadata:
  name: box2
  labels:
    app: test
spec:
  containers:
  - name: test2
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
[root@server01 ~]# kubectl apply -f pod.yaml 
pod/box1 created
pod/box2 created
#不能被接管
[root@server01 ~]# kubectl get pod --show-labels
NAME            READY   STATUS    RESTARTS   AGE     LABELS
box1            1/1     Running   0          49s     app=guestbook
box2            1/1     Running   0          49s     app=test
rs-test-47w2f   1/1     Running   0          3m38s   app=test,tier=canary
rs-test-6xxxx   1/1     Running   0          3m38s   app=test,tier=canary
rs-test-l9pgt   1/1     Running   0          3m38s   app=test,tier=canary
rs-test-q9j4m   1/1     Running   0          3m38s   app=test,tier=canary
rs-test-qxr9l   1/1     Running   0          3m38s   app=test,tier=canary
[root@server01 ~]# kubectl label pod rs-test-47w2f app=guestbook --overwrite 
pod/rs-test-47w2f labeled
[root@server01 ~]# kubectl get pod --show-labels
NAME            READY   STATUS    RESTARTS   AGE     LABELS
box1            1/1     Running   0          3m15s   app=guestbook
box2            1/1     Running   0          3m15s   app=test
rs-test-47w2f   1/1     Running   0          6m4s    app=guestbook,tier=canary
rs-test-6xxxx   1/1     Running   0          6m4s    app=test,tier=canary
rs-test-l9pgt   1/1     Running   0          6m4s    app=test,tier=canary
rs-test-q9j4m   1/1     Running   0          6m4s    app=test,tier=canary
rs-test-qxr9l   1/1     Running   0          6m4s    app=test,tier=canary
[root@server01 ~]# kubectl delete pod rs-test-6xxxx 
pod "rs-test-6xxxx" deleted
[root@server01 ~]# kubectl get pod
NAME            READY   STATUS    RESTARTS   AGE
box1            1/1     Running   0          33m
box2            1/1     Running   0          33m
rs-test-47w2f   1/1     Running   0          36m
rs-test-l9pgt   1/1     Running   0          36m
rs-test-q9j4m   1/1     Running   0          36m
rs-test-qxr9l   1/1     Running   0          36m
rs-test-zdjtr   1/1     Running   0          43s
[root@server01 ~]# kubectl get rs
NAME      DESIRED   CURRENT   READY   AGE
rs-test   5         5         5       37m
[root@server01 ~]# kubectl delete -f rs.yaml --cascade=orphan
replicaset.apps "rs-test" deleted
[root@server01 ~]# kubectl get rs
No resources found in default namespace.
[root@server01 ~]# kubectl get pod
NAME            READY   STATUS    RESTARTS   AGE
box1            1/1     Running   0          35m
box2            1/1     Running   0          35m
rs-test-47w2f   1/1     Running   0          38m
rs-test-l9pgt   1/1     Running   0          38m
rs-test-q9j4m   1/1     Running   0          38m
rs-test-qxr9l   1/1     Running   0          38m
rs-test-zdjtr   1/1     Running   0          2m10s
删除不会新建出来
[root@server01 ~]# kubectl delete pod rs-test-zdjtr
pod "rs-test-zdjtr" deleted
[root@server01 ~]# kubectl get pod
NAME            READY   STATUS    RESTARTS   AGE
box1            1/1     Running   0          39m
box2            1/1     Running   0          39m
rs-test-47w2f   1/1     Running   0          41m
rs-test-l9pgt   1/1     Running   0          41m
rs-test-q9j4m   1/1     Running   0          41m
rs-test-qxr9l   1/1     Running   0          41m
~~~

~~~shell
[root@server01 ~]# vim rs.yaml 
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs-test
  labels:
    app: guestbook
    tier: frontend
spec:
  replicas: 3
  selector:
    matchExpressions:
    - {key: app, operator: In, values: [guestbook, test]}
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: rctest
        image: httpd:latest
        imagePullPolicy: IfNotPresent
[root@server01 ~]# kubectl apply  -f rs.yaml
~~~
