# calicoctl网络策略

## 安装calicoctl

官方网站：https://github.com/

进入主界面

![image-20240729193947097](https://gitee.com/xiaojinliaqi/img/raw/master/202407291939213.png)

点击进去在右侧选择releasesv3.20.6版本

![image-20240729194007907](https://gitee.com/xiaojinliaqi/img/raw/master/202407291940993.png)



选择第四个caclicoctl在右上角把这个pull下来上传到server1主节点上/usr/local/sbin 目录下面

![image-20240729194033866](https://gitee.com/xiaojinliaqi/img/raw/master/202407291940963.png)

这个query是关于在Linux系统中使用calicoctl命令查看节点状态的操作。首先，切换到/usr/local/sbin目录，然后给calicoctl文件添加可执行权限，最后执行calicoctl node status命令查看节点状态。

~~~shell
[root@server1 ~]# cd /usr/local/sbin
[root@server1 sbin]# chmod +x /usr/local/sbin/calicoctl 
[root@server1 sbin]# calicoctl node status
~~~

![image-20240729194121250](https://gitee.com/xiaojinliaqi/img/raw/master/202407291941292.png)

### calico相关命令

~~~shell
[root@server01 ~]# kubectl get ippools.crd.projectcalico.org default-ipv4-ippool 
NAME                  AGE
default-ipv4-ippool   3d10h
[root@server01 ~]# calicoctl node status -o wide
Usage:
  calicoctl node status [--allow-version-mismatch]
[root@server01 ~]# calicoctl get node -o wide
NAME       ASN       IPV4              IPV6   
server01   (64512)   10.15.200.11/24          
server02   (64512)   10.15.200.12/24          
server03   (64512)   10.15.200.13/24          

[root@server01 ~]# calicoctl ipam show
+----------+--------------+-----------+------------+--------------+
| GROUPING |     CIDR     | IPS TOTAL | IPS IN USE |   IPS FREE   |
+----------+--------------+-----------+------------+--------------+
| IP Pool  | 10.10.0.0/16 |     65536 | 7 (0%)     | 65529 (100%) |
+----------+--------------+-----------+------------+--------------+
[root@server01 ~]# calicoctl ipam show --show-block
+----------+-----------------+-----------+------------+--------------+
| GROUPING |      CIDR       | IPS TOTAL | IPS IN USE |   IPS FREE   |
+----------+-----------------+-----------+------------+--------------+
| IP Pool  | 10.10.0.0/16    |     65536 | 7 (0%)     | 65529 (100%) |
| Block    | 10.10.10.0/26   |        64 | 1 (2%)     | 63 (98%)     |
| Block    | 10.10.188.0/26  |        64 | 4 (6%)     | 60 (94%)     |
| Block    | 10.10.40.192/26 |        64 | 1 (2%)     | 63 (98%)     |
| Block    | 10.10.6.0/26    |        64 | 1 (2%)     | 63 (98%)     |
| Block    | 10.105.199.0/26 |        64 | 6 (9%)     | 58 (91%)     |
+----------+-----------------+-----------+------------+--------------+
[root@server01 ~]# kubectl get ipamblocks.crd.projectcalico.org 
NAME              AGE
10-10-10-0-26     8h
10-10-188-0-26    8h
10-10-40-192-26   8h
10-10-6-0-26      8h
10-105-199-0-26   3d10h
[root@server01 ~]# kubectl describe ipamblocks.crd.projectcalico.org 10-10-10-0-26
[root@server01 ~]# calicoctl get ipPool
NAME                  CIDR           SELECTOR   
default-ipv4-ippool   10.10.0.0/16   all()      
[root@server01 ~]# calicoctl get felixConfiguration
NAME      
default 
[root@server01 ~]# kubectl describe felixconfigurations.crd.projectcalico.org default
~~~

### calico网络

~~~shell
[root@server01 ~]# mkdir test
[root@server01 ~]# cd test/
[root@server01 test]# ls
[root@server01 test]# kubectl api-versions | grep calico
crd.projectcalico.org/v1
[root@server01 test]# kubectl api-resources | grep calico
[root@server01 test]# kubectl api-resources -o wide
[root@server01 test]# kubectl api-resources -o wide | grep calico
[root@server01 test]# kubectl api-resources -o wide | grep calico | grep -i ippool
[root@server01 test]# vim pool1.yaml
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: pool1
spec:
  cidr: 10.254.1.0/24
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
---
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: pool2
spec:
  cidr: 10.254.2.0/24
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
[root@server01 test]# kubectl apply -f pool1.yaml 
ippool.crd.projectcalico.org/pool1 created
ippool.crd.projectcalico.org/pool2 created
# vim nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
      annotations:
        "cni.projectcoalico.org/ipv4pools": "[\"pool1\"]"
    spec:
      containers:
      - name: nginx
        image: busybox:1.36
        imagePullPolicy: IfNotPresent
        command:
        - /bin/sh
        - -c
        - sleep 1d
##最终效果   
#vim pool1.yaml 
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: pool3
spec:
  allowedUses:
  - Workload
  - Tunnel
  blockSize: 24
  cidr: 10.251.0.0/16
  ipipMode: Always
  natOutgoing: true
  disabled: false
  nodeSelector: all()
~~~

### 网络策略

pod通信可以通信的pod是通过以下标识分辨

1.单独pod限制：其他被允许的pod

2.基于namespace的限制：被允许的命名空间

3.基于ip 地址段：指定的IP地址段。例外：pod所在的节点通讯是被允许

pod的两种隔离： ==Egress出口隔离==和==ngress入口隔离==

允许入站的基础流量



