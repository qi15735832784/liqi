# securityContext安全上下文

定义：pod 或者 container 的特权与访问控制设置

包括：

1. 自主访问控制：基于UID  GID 判断访问权限
2. 安全增强：为对象赋予 seliunx 权限（停止使用）
3. 以特权模式或非特权模式运行
4. linux 权能：为进程赋予 root 账户的部分特权而非全部特权
5. AppArmor：使用程序的配置来限制个别程序的权能
6. Seccomp：过滤进程的系统调用
7. allowPrivilegeEscalation：表示进程是否以获得超过父进程的特权
8. readOnlyRootFilesystem：以只读的方式挂载根目录



在 Kubernetes 中创建并管理一个简单的 Pod，以及如何进入该 Pod 内部查看容器的运行情况和当前用户的身份信息

~~~shell
[root@server01 8_8]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
  - name: main
    image: busybox:1.36
    imagePullPolicy: IfNotPresent
    command:
    - /bin/sh
    - -c
    - sleep 1d
[root@server01 8_8]# kubectl apply -f pod.yaml
[root@server01 8_8]# kubectl get pod
NAME   READY   STATUS    RESTARTS   AGE
web    1/1     Running   0          92s
[root@server01 8_8]# kubectl exec -it web -- sh
/ # whoami 
root
/ # id
uid=0(root) gid=0(root) groups=0(root),10(wheel)
#最后删除即可
[root@server01 8_8]# kubectl delete -f pod.yaml --force --grace-period 0
~~~

在 Kubernetes 中创建带有自定义安全上下文的 Pod，并进入容器内部查看容器运行时的用户身份信息

~~~shell
[root@server01 8_8]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
  - name: main
    image: busybox:1.36
    imagePullPolicy: IfNotPresent
    command:
    - /bin/sh
    - -c
    - sleep 1d
    securityContext:   #指定了容器运行时的安全上下文
      runAsUser: 10000   #将容器的 runAsUser 设置为 10000
[root@server01 8_8]# kubectl apply -f pod.yaml
[root@server01 8_8]# kubectl get pod
NAME   READY   STATUS    RESTARTS   AGE
web    1/1     Running   0          111s
[root@server01 8_8]# kubectl exec -it web -- sh
~ $ id
uid=10000 gid=0(root) groups=0(root)
#最后删除即可
[root@server01 8_8]# kubectl delete -f pod.yaml --force --grace-period 0
~~~

在 Kubernetes 中创建带有自定义安全上下文的 Pod，并验证了容器内部进程的用户和组信息，以及对挂载数据卷的权限控制

```shell
[root@server01 8_8]# vim securityContext.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod
spec:
  securityContext:
    runAsUser: 1000   #指定了容器内进程的运行用户为 1000
    runAsGroup: 3000   #指定了容器内进程的运行组为 3000
    fsGroup: 2000   #指定了挂载到容器内的数据卷 sec-ctx-vol 的文件系统组为 2000
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  containers:
  - name: sec-ctx-demo
    image: busybox:1.36
    imagePullPolicy: IfNotPresent
    command: ["sh","-c","sleep 1d"]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      allowPrivilegeEscalation: false   #禁止容器内进程提升特权
[root@server01 8_8]# kubectl apply -f securityContext.yaml
[root@server01 8_8]# kubectl get pod
NAME   READY   STATUS    RESTARTS   AGE
pod    1/1     Running   0          10s
[root@server01 8_8]# kubectl exec -it pod -- sh
~ $ ps
PID   USER     TIME  COMMAND
    1 1000      0:00 sh -c sleep 1d
    7 1000      0:00 sh
   12 1000      0:00 ps
~ $ cd /data/
/data $ ls -l
total 0
drwxrwsrwx    2 root     2000             6 Aug  8 02:17 demo
/data $ cd demo/
/data/demo $ echo hello > testfile
/data/demo $ ls -l
total 4
-rw-r--r--    1 1000     2000             6 Aug  8 02:19 testfile
/data/demo $ id
uid=1000 gid=3000 groups=2000,3000
##id 命令查看了当前用户的详细身份信息：
#uid=1000 表示当前用户的 UID 是 1000，符合安全上下文中指定的 runAsUser。
#gid=3000 表示当前用户的 GID 是 3000，符合安全上下文中指定的 runAsGroup。
#groups=2000,3000 表示当前用户同时属于 2000 和 3000 两个组，其中 2000 是挂载数据卷时指定的 fsGroup。
##最后删除即可
[root@server01 8_8]# kubectl delete -f securityContext.yaml --force
```



## RBAC 权限管理:Role Based Access Control

认证:解决用户是谁的问题

授权: 解决用户能做什么的问题

API 访问需要经过三个步骤：认证sa→授权role→准入bind

逻辑是:

通过角色关联 用户，角色关联权限，间接为用户赋予权限.

涉及到的几个概念：

1. Rule:规则,一组不同的 API Group 的操作集合
2. Role:角色,用于定义一组对 k8sAPI 对象操作规则。范围限定在namespace
3. ClusterRole:集群角色，该角色不受namespace的限制
4. Subject:对象，也是就是规则作用的角色
5. RoleBinding:将角色和对象进行绑定，范围限定在 namespace 中
6. ClusterRoleBinding:将集群角色和对象进行绑定,不受 namespace 限制
7. serviceaccount:是kubernetes 中的一个 API对象，用于为应用程序提供身份验证 和授权的机制。已经允许应用程序以特定的用户身份运行，并具有相应的权限

# kubernetes中提供四中鉴权模式

1. node 一种特殊的授权模块,基于 node 上运行的 pod 为 kubelet 授权即:允许节点上的 pod 使用节点的证书进行身份验证，这种模式下，只有与节点关联的 pod 才可以访问 API server.
2. ABAC 基于属性的访问控制
3. RBAC 基于角色的访问控制
4. webhook HTTP 访问请求回调,通过一个 web的用用鉴权是否有权限进行某项操作。

RoleBinding\Role 的 subject包含:namespace pod secret Deployment configmap 等等

clusterRoleBinding\clusterRole 包含:rules动作和资源，subject 和 PV等

## resources：列出哪些资源受到策略影响

例如：pods services deployment

verbs:列出允许进行的http 动作.常见是 get list watch

例如:

1. get 获取资源的详细信息
2. list 列出资源的集合
3. watch·监视资源的更改
4. create 创建资源的实例
5. update 更新现有资源的属性
6. path 部分更新现有资源属性delete 删除单个资源的权限deletecollection·删除资源的集合impersonate 代表其他用户或租的操作bind 将角色绑定到用户\组\执行操作escalate 升级权限(特权)

~~~shell
[root@server01 role]# vim roledemo.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:   #定义了 Role 的权限规则
- apiGroups: [""]   #表示作用于核心 API 组
  resources: ["pods"]   #表示可以操作的资源是 Pods
  verbs: ["get","list","watch"]   #表示允许执行的动作包括获取（get）、列出（list）、和监视（watch）
[root@server01 role]# kubectl apply -f roledemo.yaml
[root@server01 role]# kubectl get role
NAME         CREATED AT
pod-reader   2024-08-08T03:13:39Z
[root@server01 role]# kubectl describe role pod-reader
~~~

![image-20240808112042181](https://gitee.com/xiaojinliaqi/img/raw/master/202408081120219.png)

clusterRole:适用于集群内的范围，可以授权

1. 集群范围内的资源点:比如 node
2. 非资源点:比如 /health
3. 跨空间访问:kubectl get pod --all-namespace



~~~shell
[root@server01 role]# vim cluterroledemo.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:   #定义了 ClusterRole 的权限规则
- apiGroups: [""]   #表示作用于核心 API 组
  resources: ["secrets"]   #表示可以操作的资源是 Secrets
  verbs: ["get","list","watch"]   #表示允许执行的动作包括获取（get）、列出（list）、和监视（watch）
[root@server01 role]# kubectl apply -f cluterroledemo.yaml
[root@server01 role]# kubectl describe clusterroles.rbac.authorization.k8s.io secret-reader
~~~

![image-20240808114037122](https://gitee.com/xiaojinliaqi/img/raw/master/202408081140161.png)



