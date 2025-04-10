# serviceaccount的权限

## 实验

[官网](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/ 'https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/')



![image-20240807104127113](https://gitee.com/xiaojinliaqi/img/raw/master/202408071041185.png)

![image-20240807104200348](https://gitee.com/xiaojinliaqi/img/raw/master/202408071042433.png)

添加 Helm 仓库：为 Helm 添加一个新的 Chart 仓库

~~~shell
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
~~~

列出当前已配置的 Helm 仓库

~~~shell
helm repo list
~~~

![image-20240807093016394](https://gitee.com/xiaojinliaqi/img/raw/master/202408070930523.png)

搜索仓库中的 Helm Charts

~~~shell
helm search repo kubernetes-dashboard
~~~

![image-20240807093358210](https://gitee.com/xiaojinliaqi/img/raw/master/202408070933257.png)

下载 Helm Chart 包

~~~shell
helm pull kubernetes-dashboard/kubernetes-dashboard
~~~

![image-20240807093914161](https://gitee.com/xiaojinliaqi/img/raw/master/202408070939187.png)

解压 Chart 包，进入解压后的目录

~~~shell
tar -zxf kubernetes-dashboard-7.5.0.tgz
cd kubernetes-dashboard/
~~~

创建 `kubernetes-dashboard` 命名空间

~~~shell
kubectl create namespace kubernetes-dashboard
~~~

安装 Kubernetes Dashboard（在 `kubernetes-dashboard` 命名空间中使用当前目录中的 Chart 安装 `kubernetes-dashboard`）

~~~shell
helm install kubernetes-dashboard --namespace kubernetes-dashboard .
~~~

![image-20240807095344541](https://gitee.com/xiaojinliaqi/img/raw/master/202408070953736.png)

列出 `kubernetes-dashboard` 命名空间中的所有 Pod

~~~shell
kubectl get pod --namespace kubernetes-dashboard
~~~

![image-20240807095602205](https://gitee.com/xiaojinliaqi/img/raw/master/202408070956243.png)

列出 `kubernetes-dashboard` 命名空间中的所有服务

~~~shell
kubectl get service --namespace kubernetes-dashboard
~~~

![image-20240807100539495](https://gitee.com/xiaojinliaqi/img/raw/master/202408071005532.png)

编辑 `kubernetes-dashboard` 命名空间中的 `kubernetes-dashboard-kong-proxy` 服务的配置

~~~shell
kubectl edit --namespace kubernetes-dashboard service kubernetes-dashboard-kong-proxy
~~~

 ![image-20240807100446975](https://gitee.com/xiaojinliaqi/img/raw/master/202408071004015.png)

再次查看服务状态

~~~shell
kubectl get service --namespace kubernetes-dashboard
~~~

![image-20240807103656671](https://gitee.com/xiaojinliaqi/img/raw/master/202408071036713.png)

浏览器验证

~~~shell
https://10.15.200.11:40080
~~~

![image-20240807104756338](https://gitee.com/xiaojinliaqi/img/raw/master/202408071047410.png)



在 kubernets 中有两种账户：
1.用于登录 kubernetes 的
2.sa 用来创建 pod 的

### 创建

#### 创建一个 Service Account

在 `kubernetes-dashboard` 命名空间中创建一个名为 `admin-user` 的 Service Account

```shell
apiVersion: v1   #这是 API 版本
kind: ServiceAccount   #这是资源类型，表示你要创建一个 Service Account
metadata:   #包含资源的元数据
  name: admin-user   #这是 Service Account 的名称
  namespace: kubernetes-dashboard   #这是 Service Account 所在的命名空间
```

#### 创建 ClusterRoleBinding

在大多数情况下，使用 kops、kubeadm 或其他流行工具配置集群后，`cluster-admin` ClusterRole 已经存在于集群中。我们可以直接使用这个角色，只需为我们的 ServiceAccount 创建一个 ClusterRoleBinding。如果该角色不存在，则需要首先创建此角色，并手动授予所需的权限

```shell
apiVersion: rbac.authorization.k8s.io/v1   #这是 RBAC API 的版本
kind: ClusterRoleBinding   #这是资源类型，表示你要创建一个 ClusterRoleBinding
metadata:   #包含资源的元数据
  name: admin-user   #这是 ClusterRoleBinding 的名称
roleRef:   #指定 ClusterRoleBinding 绑定到哪个角色
  apiGroup: rbac.authorization.k8s.io   #API 组
  kind: ClusterRole   #角色类型，这里是 ClusterRole
  name: cluster-admin   #ClusterRole 的名称，这里使用 cluster-admin，这是一个预定义的角色，通常在集群中已经存在
subjects:   #指定该 ClusterRoleBinding 绑定到哪些对象
- kind: ServiceAccount   #对象类型，这里是 Service Account
  name: admin-user   #Service Account 的名称
  namespace: kubernetes-dashboard   #Service Account 所在的命名空间
```

##### 总结

你正在执行以下操作：

1. 在 `kubernetes-dashboard` 命名空间中创建一个名为 `admin-user` 的 Service Account。
2. 创建一个 ClusterRoleBinding，将 `admin-user` Service Account 绑定到 `cluster-admin` ClusterRole，使 `admin-user` 拥有集群管理员权限。

编辑 admin-user.yaml 文件

~~~shell
vim admin-user.yaml 
###
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
~~~

部署

~~~shell
kubectl apply -f admin-user.yaml
~~~

列出 `kubernetes-dashboard` 命名空间中所有的 Service Accounts

~~~shell
kubectl get serviceaccounts --namespace kubernetes-dashboard 
~~~

![image-20240807114642043](https://gitee.com/xiaojinliaqi/img/raw/master/202408071146094.png)

为 `kubernetes-dashboard` 命名空间中的 `admin-user` Service Account 创建一个访问令牌（token）。这个令牌可以用于认证和访问 Kubernetes API

~~~shell
kubectl -n kubernetes-dashboard create token admin-user
~~~

![image-20240807115057447](https://gitee.com/xiaojinliaqi/img/raw/master/202408071150500.png)

~~~sh
eyJhbGciOiJSUzI1NiIsImtpZCI6InBROUI4cEhrNVZHVVZMem8yZTZYOWItVHJiRTdRRDR4R18tRGRGekd5V2sifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzIzMDAyNzM2LCJpYXQiOjE3MjI5OTkxMzYsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiOTQyNTczOTgtNTkwZS00MDA1LWI5MmMtZjhiYTczNzdlMDQzIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi11c2VyIiwidWlkIjoiMjA4ZWUzMmYtZjRiYS00YmFlLWIzMGEtODM5NzIwOWE1YmFmIn19LCJuYmYiOjE3MjI5OTkxMzYsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbi11c2VyIn0.soCveoS2AfYYM8nhLIO3Llk6f2Mr71peTp0FDzmRql3bz797nBkjr8N7AxbESd4eyfMUIK-yoibiQGS9JtOq26qWBM7YYyRmhyL20EYjWrAW8xXg4zTaKQtwulih2qXUvM5zqXNk1rjBpanHla5W5DZDGTeONm8alYJQYKblfuxH4o20SUBnE4jWtgJx35VPG9uBI7Zj2t1cJbGiiw4f0SwSXZ6mccr0zG0gKaIOd5h3xIqNJP2YR6RKbERQnPgr6ohNdhqy40Nf85qnZ80IFvGss8Rwa5xQ4308teu3gBtUhphtSMd7015Vtd3rBBvSS5fJ_H5mSBneYf27mAhA6Q
~~~

使用生成的访问令牌登陆

![image-20240807115824558](https://gitee.com/xiaojinliaqi/img/raw/master/202408071158641.png)

部署完Pod 查看默认

~~~shell
[root@server01 8_7]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
  - name: main
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
[root@server01 8_7]# kubectl apply -f pod.yaml
[root@server01 8_7]# kubectl describe pod web
~~~

![image-20240807181735007](https://gitee.com/xiaojinliaqi/img/raw/master/202408071817204.png)



~~~shell
[root@server01 8_7]# kubectl create serviceaccount sal
serviceaccount/sal created
[root@server01 8_7]# kubectl get serviceaccounts 
NAME      SECRETS   AGE
default   0         15d
sal       0         56m
~~~

![image-20240807191557817](https://gitee.com/xiaojinliaqi/img/raw/master/202408071915857.png)

设置sa1

~~~shell
[root@server01 8_7]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  serviceAccountName: sa1
  containers:
  - name: main
    image: nginx:1.24
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
[root@server01 8_7]# kubectl apply -f pod.yaml 
[root@server01 8_7]# kubectl describe pod
~~~

![image-20240807192536167](https://gitee.com/xiaojinliaqi/img/raw/master/202408071925223.png)

查看投射卷

~~~shell
[root@server01 8_7]# kubectl exec -it web -- bash
df-Th
~~~

![image-20240807200053403](https://gitee.com/xiaojinliaqi/img/raw/master/202408072000442.png)

每次重新部署都会生成新的token

~~~shell
kubectl exec pods/web -- cat /run/secrets/kubernetes.io/serviceaccount/token
~~~



![image-20240807202056872](https://gitee.com/xiaojinliaqi/img/raw/master/202408072020920.png)

https://jwt.io/

![image-20240807202218851](https://gitee.com/xiaojinliaqi/img/raw/master/202408072022922.png)

创建一个有效期为 8760 小时的令牌

~~~shell
kubectl create token sa1 --duration 8760h
~~~

![image-20240807203600221](https://gitee.com/xiaojinliaqi/img/raw/master/202408072036270.png)



通过 secret 的 token 即是永不过期的 service account
通过 Service Account 自定义权限

创建永不过期的Service Account

~~~shell
[root@server01 8_7]# vim secretoken.yaml 
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: default
  annotations:
    kubernetes.io/service-account.name: "sa1"
[root@server01 8_7]# kubectl apply -f secretoken.yaml 
[root@server01 8_7]# kubectl describe secrets default
~~~

![image-20240807205434780](https://gitee.com/xiaojinliaqi/img/raw/master/202408072054858.png)

把上面token值复制粘贴，就不会有时间显示

![image-20240807205535087](https://gitee.com/xiaojinliaqi/img/raw/master/202408072055161.png)



~~~shell
[root@server01 8_7]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  serviceAccountName: sa1   #Pod 使用的 ServiceAccount 名称
  containers:
  - name: main   #容器的名称
    image: busybox:1.36
    imagePullPolicy: IfNotPresent   #拉取镜像的策略
    command: ["/bin/sh","-c","sleep 1d"]   #指定容器启动时执行的命令
    volumeMounts:
    - name: sa1-token   #挂载的卷名称
      mountPath: /var/run/secrets/tokens   #容器内的挂载路径
  volumes:
  - name: sa1-token   #卷的名称
    projected:
      sources:
      - serviceAccountToken:
          path: sa1-token   #投影到容器内的路径
          expirationSeconds: 7200   #令牌的有效期（秒）
          audience: vault   #令牌的受众
[root@server01 8_7]# kubectl apply -f pod.yaml
[root@server01 8_7]# kubectl exec -it web -- sh
/ # cd /var/run/secrets/tokens/
/var/run/secrets/tokens # ls
sa1-token
/var/run/secrets/tokens # cat sa1-token 
~~~

![image-20240807212659165](https://gitee.com/xiaojinliaqi/img/raw/master/202408072126223.png)

查看到的token粘贴到网站里

![image-20240807212531126](https://gitee.com/xiaojinliaqi/img/raw/master/202408072125203.png)



权限验证命令——检查一个指定的 ServiceAccount 是否有权限执行某个操作

~~~shell
[root@server01 8_7]# kubectl --as=system:serviceaccount:default:sa1 auth can-i get pod
~~~

把原来的busybox:1.36的镜像换成nginx:latest

~~~shell
[root@server01 8_7]# vim pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  serviceAccountName: sa1
  containers:
  - name: main
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
[root@server01 8_7]# kubectl apply -f pod.yaml
~~~

在 Pod 内部执行了一系列命令来获取 Kubernetes API Server 的认证信息，并使用这些信息发送 HTTP 请求来获取当前命名空间中的 Pod 列表。这是为了验证 ServiceAccount 的权限，并查看它是否能够访问 Kubernetes API

~~~shell
[root@server01 8_7]# kubectl exec -it web -- bash
root@web:/# curl 127.0.0.1
root@web:/# df -Th
Filesystem          Type     Size  Used Avail Use% Mounted on
overlay             overlay   36G  9.4G   26G  27% /
tmpfs               tmpfs     64M     0   64M   0% /dev
/dev/mapper/rl-root xfs       36G  9.4G   26G  27% /etc/hosts
shm                 tmpfs     64M     0   64M   0% /dev/shm
tmpfs               tmpfs    3.5G   12K  3.5G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs               tmpfs    1.8G     0  1.8G   0% /proc/acpi
tmpfs               tmpfs    1.8G     0  1.8G   0% /proc/scsi
tmpfs               tmpfs    1.8G     0  1.8G   0% /sys/firmware
root@web:/# ls /run/secrets/kubernetes.io/serviceaccount
ca.crt  namespace  token
root@web:/# dir=/run/secrets/kubernetes.io/serviceaccount
root@web:/# CA_CERT=$dir/ca.crt
root@web:/# TOKEN=$(cat $dir/token)
root@web:/# NAMESPACE=$(cat $dir/namespace)
root@web:/# curl --cacert $CA_CERT -H "Authorization: Bearer $TOKEN" "https://kubernetes.default/api/v1/namespaces/$NAMESPACE/pods/"
~~~

![image-20240807221536008](https://gitee.com/xiaojinliaqi/img/raw/master/202408072215073.png)

创建了一个 ClusterRoleBinding，将 `cluster-admin` 集群角色绑定到命名空间 `default` 中的 `sa1` ServiceAccount。这将赋予 `sa1` ServiceAccount 集群管理员的所有权限

~~~shell
kubectl create clusterrolebinding cbind1 --clusterrole cluster-admin --serviceaccount default:sa1
kubectl --as=system:serviceaccount:default:sa1 auth can-i get pod
#删除 ClusterRoleBinding 方法
kubectl delete clusterrolebinding cbind1
~~~

![image-20240807223130365](https://gitee.com/xiaojinliaqi/img/raw/master/202408072231416.png)

总结：

SA 的权限越高，token 的权限就越高，pod 中的”app 程序“的权限能访问 kubernetes 中的资源权限就越高
