# 搭建私人的repo



哪台需要做私人的repo，就往哪台上拷贝

~~~she
scp /usr/local/sbin/helm server02:/usr/local/sbin/helm
scp /usr/local/sbin/helmify server02:/usr/local/sbin/helmify
~~~

在02上安装httpd

~~~shell
dnf install httpd -yq
systemctl start httpd
cd /var/www/html/
mkdir charts
~~~

把主节点制作的nginx-li-0.1.0.tgz拷贝到02

~~~shell
scp nginx-li-0.1.0.tgz server02:/var/www/html/charts
~~~

在02上启用 Helm 自动补全功能

~~~shell
source <(helm completion bash)
vim ~/.bashrc
在最后添加：source <(helm completion bash)
~~~

更新 Helm 仓库索引

~~~shell
helm repo index ./charts/
~~~

查看目录结构

~~~shell
tree charts/
~~~

 ![image-20240806215024580](https://gitee.com/xiaojinliaqi/img/raw/master/202408062150621.png)

查看仓库索引文件

~~~shell
cat charts/index.yaml 
~~~

![image-20240806215001658](https://gitee.com/xiaojinliaqi/img/raw/master/202408062150753.png)

将一个名为 `lisir` 的 Helm 仓库添加到 Helm 客户端中，仓库的 URL 是 `http://10.15.200.12/charts`

~~~shell
[root@server01 repo]# helm repo add lisir http://10.15.200.12/charts
~~~

从私人仓库安装

~~~shell
[root@server01 repo]# helm install li lisir/nginx-li
NAME: li
LAST DEPLOYED: Tue Aug  6 22:24:41 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
[root@server01 repo]# helm list 
NAME    NAMESPACE       REVISION        UPDATED                                      STATUS          CHART           APP VERSION
li      default         1               2024-08-06 22:24:41.092636022 +0800 CST      deployed        nginx-li-0.1.0  0.1.0      
[root@server01 repo]# kubectl get pod
NAME                               READY   STATUS    RESTARTS   AGE
li-nginx-li-web-587669fbf4-ns8jh   1/1     Running   0          39s
li-nginx-li-web-587669fbf4-sbd8q   1/1     Running   0          39s
li-nginx-li-web-587669fbf4-wqx9g   1/1     Running   0          39s

# 编辑 Kubernetes 配置文件
[root@server01 QOS]# vim mysql.yaml 
###
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql 
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql 
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: 123.com
---
apiVersion: v1
kind: Service
metadata:
  name: mysqlsvc
spec:
  selector:
    app: mysql
  ports:
  - protocol: TCP
    port: 3306
    targetPort: 3306
    
# 使用 Helmify 转换为 Helm Chart    
[root@server01 QOS]# helmify -f mysql.yaml mysql-li

# 打包 Helm Chart
[root@server01 QOS]# helm package mysql-li

#将打包的文件传输到服务器
[root@server01 QOS]# scp mysql-li-0.1.0.tgz server02:/var/www/html/charts

~~~

在02上

~~~shell
[root@server02 ~]# cd /var/www/html/
# 生成或更新指定目录中的 index.yaml 文件，并将其与现有的 index.yaml 文件合并
[root@server02 html]# helm repo index ./charts/ --merge ./charts/index.yaml 
[root@server02 html]# cat charts/index.yaml 
apiVersion: v1
entries:
  mysql-li:
  - apiVersion: v2
    appVersion: 0.1.0
    created: "2024-08-06T22:48:02.316830188+08:00"
    description: A Helm chart for Kubernetes
    digest: b70f4164424eb1ad94578dfecb41750aabf9447e3523cf507325de4fd6fe0b44
    name: mysql-li
    type: application
    urls:
    - mysql-li-0.1.0.tgz
    version: 0.1.0
  nginx-li:
  - apiVersion: v2
    appVersion: 0.1.0
    created: "2024-08-06T22:48:02.317429164+08:00"
    description: A Helm chart for Kubernetes
    digest: fe99f3072e2fcb1e9d22a0e06b20d4ef88681934742a03ce8ebd68b82ec3c01c
    name: nginx-li
    type: application
    urls:
    - nginx-li-0.1.0.tgz
    version: 0.1.0
generated: "2024-08-06T22:48:02.309228601+08:00"
~~~

在02上修改

~~~shell
[root@server02 html]# cat charts/index.yaml 
apiVersion: v1
entries:
  mysql-li:
  - apiVersion: v2
    appVersion: 0.1.0
    created: "2024-08-06T22:48:02.316830188+08:00"
    description: The mysql by lisir
    digest: b70f4164424eb1ad94578dfecb41750aabf9447e3523cf507325de4fd6fe0b44
    name: mysql-li
    type: application
    urls:
    - mysql-li-0.1.0.tgz
    version: 0.1.0
  nginx-li:
  - apiVersion: v2
    appVersion: 0.1.0
    created: "2024-08-06T22:48:02.317429164+08:00"
    description: The web server of nginx by lisir
    digest: fe99f3072e2fcb1e9d22a0e06b20d4ef88681934742a03ce8ebd68b82ec3c01c
    name: nginx-li
    type: application
    urls:
    - nginx-li-0.1.0.tgz
    version: 0.1.0
generated: "2024-08-06T22:48:02.309228601+08:00"
~~~

在01上

~~~shell
[root@server01 ~]# cd repo/
[root@server01 repo]# helm repo list 
NAME    URL                               
bitnami https://charts.bitnami.com/bitnami
lisir   http://10.15.200.12/charts        
[root@server01 repo]# helm repo update lisir 
[root@server01 repo]# helm search repo lisir
NAME            CHART VERSION   APP VERSION     DESCRIPTION                     
lisir/mysql-li  0.1.0           0.1.0           The mysql by lisir              
lisir/nginx-li  0.1.0           0.1.0           The web server of nginx by lisir

~~~

