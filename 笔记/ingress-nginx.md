# ingress-nginx

基础配置

安装ingress

主装的

~~~shell
# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/controller:v1.10.1
# nerdctl login --username=aliyun3894322220 registry.cn-zhangjiakou.aliyuncs.com
# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/controller:v1.10.1
# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/kube-webhook-certgen:v1.4.1
~~~

其次的两台

~~~shell
# nerdctl login --username=aliyun3894322220 registry.cn-zhangjiakou.aliyuncs.com
# nerdctl --namespace k8s.io pull registry.cn-zhangjiakou.aliyuncs.com/xiaojinliaqi/kube-webhook-certgen:v1.4.1
~~~



server02,server03创建文件，编写网页

~~~shell
mkdir /www/nginx -p
mkdir /www/httpd -p
echo "You visited nginx cluster!" > /www/nginx/index.html
echo "You visited httpd cluster!" > /www/httpd/index.html
~~~



~~~shell
[root@server01 test]# kubectl get pods -n ingress-nginx
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-72tzz        0/1     Completed   0          21h
ingress-nginx-admission-patch-4rcvl         0/1     Completed   1          21h
ingress-nginx-controller-86cf98c57f-cm7bc   1/1     Running     0          21h
[root@server01 test]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-cluster
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
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: www
        hostPath:
          path: /www/nginx
---
apiVersion: v1
kind: Service
metadata:
  name: nginxsvc
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
[root@server01 test]# kubectl apply -f nginx.yaml 
[root@server01 test]# kubectl get pod
NAME                             READY   STATUS    RESTARTS   AGE
nginx-cluster-5dcb7bbd58-2lj8g   1/1     Running   0          4m56s
nginx-cluster-5dcb7bbd58-gb8g2   1/1     Running   0          4m56s
nginx-cluster-5dcb7bbd58-vg8z9   1/1     Running   0          4m56s
[root@server01 test]# kubectl get service
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP   9d
nginxsvc     ClusterIP   10.100.171.101   <none>        80/TCP    5m3s
[root@server01 test]# curl 10.100.171.101 
You visited nginx cluster!

[root@server01 test]# vim single.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: single-ingress
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: nginxsvc
      port:
        number: 80
[root@server01 test]# kubectl apply -f single.yaml 
ingress.networking.k8s.io/single-ingress created
[root@server01 test]# kubectl get ingress
NAME             CLASS   HOSTS   ADDRESS   PORTS   AGE
single-ingress   nginx   *                 80      16s

#访问安装ingress的那台节点
[root@server01 test]# curl 10.15.200.11
You visited nginx cluster!

~~~

多主机配置（根据不同的域名进行访问）

~~~shell
[root@server01 test]# vim httpd.yaml 
apiVersion: apps/v1   #指定 API 版本为 apps/v1，用于 Deployment 对象
kind: Deployment   #定义资源类型为 Deployment，用于管理 Pod 的副本
metadata:
  name: httpd-cluster   #Deployment 的名称为 httpd-cluster
spec:
  replicas: 3   #定义了 3 个 Pod 副本，确保始终有 3 个 Apache 服务器运行
  selector:
    matchLabels:
      app: httpd   #选择具有标签 app: httpd 的 Pod
  template:
    metadata:
      labels:
        app: httpd   #为 Pod 模板添加标签 app: httpd
    spec:
      containers:   #定义了 Pod 中的容器
      - name: httpd
        image: httpd:latest
        imagePullPolicy: IfNotPresent   #如果本地存在镜像，则不拉取
        ports:
        - containerPort: 80   #容器暴露 80 端口
        volumeMounts:
        - name: www
          mountPath: /usr/local/apache2/htdocs/   #挂载名为 www 的卷到容器的 /usr/local/apache2/htdocs/ 目录
      volumes:
      - name: www
        hostPath:
          path: /www/httpd
---
apiVersion: v1
kind: Service
metadata:
  name: httpdsvc
spec:
  selector:
    app: httpd
  ports:
  - name: http
    port: 80   #暴露的端口为 80
    targetPort: 80   #Pod 的目标端口为 80
[root@server01 test]# kubectl apply -f httpd.yaml
deployment.apps/httpd-cluster created
service/httpdsvc created
[root@server01 test]# kubectl get service
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
httpdsvc     ClusterIP   10.100.154.82    <none>        80/TCP    74s
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP   10d
nginxsvc     ClusterIP   10.100.171.101   <none>        80/TCP    10h
[root@server01 test]# curl 10.100.154.82
You visited httpd cluster!
[root@server01 test]# curl 10.100.171.101
You visited nginx cluster!

##写一个多域名的yaml文件（要注意两个service的名字）
[root@server01 test]# vim moredomain.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: http-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: "nginx.li.com"
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: nginxsvc
            port:
              number: 80
  - host: "httpd.li.com"
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: httpdsvc
            port:
              number: 80
[root@server01 test]# kubectl apply -f moredomain.yaml 
ingress.networking.k8s.io/http-ingress created
[root@server01 test]# vim /etc/hosts
添加10.15.200.11 nginx.li.com httpd.li.com   #ip是安装ingress的那台节点
[root@server01 test]# curl nginx.li.com
You visited nginx cluster!
[root@server01 test]# curl httpd.li.com
You visited httpd cluster!
[root@server01 test]# curl -H "host: httpd.li.com" http://10.15.200.11   #ip是安装ingress的那台节点
You visited httpd cluster!
[root@server01 test]# curl -H "host: nginx.li.com" http://10.15.200.11   #ip是安装ingress的那台节点
You visited nginx cluster!

##最后删除即可
[root@server01 test]# kubectl delete -f moredomain.yaml
~~~

第二个实验：添加url路径（同一域名，不同service）

~~~shell
##先去server02,server03创建文件
[root@server02 ~]# mkdir /www/nginx/prod
[root@server02 ~]# mkdir /www/httpd/test
[root@server02 ~]# echo "httpd test" > /www/httpd/test/index.html
[root@server02 ~]# echo "nginx prod" > /www/nginx/prod/index.html

##在server01配置
[root@server01 test]# vim url.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: http-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: "nginx.li.com"
    http:
      paths:
      - pathType: Prefix
        path: /prod
        backend:
          service:
            name: nginxsvc
            port:
              number: 80
  - host: "httpd.li.com"
    http:
      paths:
      - pathType: Prefix
        path: /test
        backend:
          service:
            name: httpdsvc
            port:
              number: 80
[root@server01 test]# kubectl apply -f url.yaml 
[root@server01 test]# kubectl get ingress
NAME             CLASS   HOSTS                       ADDRESS   PORTS   AGE
http-ingress     nginx   nginx.li.com,httpd.li.com             80      95s
single-ingress   nginx   *                                     80      10h
[root@server01 test]# curl nginx.li.com/prod/
nginx prod
[root@server01 test]# curl httpd.li.com/test/
httpd test

##最后删除即可
[root@server01 test]# kubectl delete -f url.yaml 
~~~

地址重定向（例子：输入baidu.com，他会跳转到[www.baidu.com）](http://www.baidu.com）)

~~~shell
[root@server01 test]# vim rewrite.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: https://www.baidu.com
spec:
  ingressClassName: nginx
  rules:
  - host: "nginx.li.com"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: nginxsvc
            port:
              number: 80
[root@server01 test]# kubectl apply -f rewrite.yaml 
[root@server01 test]# kubectl get ingress
NAME             CLASS   HOSTS          ADDRESS   PORTS   AGE
rewrite          nginx   nginx.li.com             80      53s
single-ingress   nginx   *                        80      11h
[root@server01 test]# curl -L nginx.li.com
[root@server01 test]# curl -L -I nginx.li.com
HTTP/1.1 302 Moved Temporarily
Date: Fri, 02 Aug 2024 01:49:41 GMT
Content-Type: text/html
Content-Length: 138
Connection: keep-alive
Location: https://www.baidu.com

##最后删除即可
[root@server01 test]# kubectl delete -f rewrite.yaml
~~~

灰度发布的两种形式

```shell
##去server02,server03创建文件
[root@server02 ~]# mkdir /www/old
[root@server02 ~]# mkdir /www/new
[root@server02 ~]# echo "old version" > /www/old/index.html
[root@server02 ~]# echo "new version" > /www/new/index.html

##在server01上删除之前部署的yaml文件
[root@server01 test]# kubectl delete -f nginx.yaml 
[root@server01 test]# kubectl delete -f httpd.yaml 

##部署old版本
[root@server01 test]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: old-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: old-nginx
  template:
    metadata:
      labels:
        app: old-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: www
        hostPath:
          path: /www/old
---
apiVersion: v1
kind: Service
metadata:
  name: nginxsvc
spec:
  selector:
    app: old-nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
[root@server01 test]# kubectl apply -f nginx.yaml 
deployment.apps/old-nginx created
service/nginxsvc created
[root@server01 test]# kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   10d
nginxsvc     ClusterIP   10.100.244.25   <none>        80/TCP    20s
[root@server01 test]# curl 10.100.244.25
old version
[root@server01 test]# vim old-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: old-release
spec:
  ingressClassName: nginx
  rules:
  - host: www.li.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginxsvc
            port:
              number: 80
[root@server01 test]# kubectl apply -f old-ingress.yaml 

[root@server01 test]# vim /etc/hosts
#添加10.15.200.11 www.li.com
[root@server01 test]# curl www.li.com
old version

##模拟新版本
[root@server01 test]# cp nginx.yaml new-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: new-nginx
  template:
    metadata:
      labels:
        app: new-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: www
        hostPath:
          path: /www/new
---
apiVersion: v1
kind: Service
metadata:
  name: newnginxsvc
spec:
  selector:
    app: new-nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
[root@server01 test]# kubectl apply -f new-nginx.yaml
[root@server01 test]# kubectl get service
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes    ClusterIP   10.96.0.1        <none>        443/TCP   10d
newnginxsvc   ClusterIP   10.100.129.127   <none>        80/TCP    2m6s
nginxsvc      ClusterIP   10.100.244.25    <none>        80/TCP    43m
[root@server01 test]# curl 10.100.129.127
new version

##金丝雀发布
[root@server01 test]# cp old-ingress.yaml new-ingress.yaml 
[root@server01 test]# vim new-ingress.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-release
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"   #启用金丝雀发布功能。这意味着 Ingress Controller 会将一小部分流量路由到带有特定标签的 Pod，用于测试新版本的应用
    nginx.ingress.kubernetes.io/canary-by-header: "vip"   #指定使用 HTTP 请求头 vip 的值来决定是否将请求路由到金丝雀版本
    nginx.ingress.kubernetes.io/canary-by-header-value: "10"   #如果请求头 vip 的值为 "10"，则该请求会被路由到金丝雀版本
spec:
  ingressClassName: nginx
  rules:
  - host: www.li.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: newnginxsvc
            port:
              number: 80
[root@server01 test]# kubectl apply -f new-ingress.yaml 
ingress.networking.k8s.io/new-release created
[root@server01 test]# kubectl get ingress
NAME             CLASS   HOSTS        ADDRESS   PORTS   AGE
new-release      nginx   www.li.com             80      20s
old-release      nginx   www.li.com             80      15m
single-ingress   nginx   *                      80      13h
[root@server01 test]# curl www.li.com
old version
[root@server01 test]# curl -H "vip:10" www.li.com
new version
[root@server01 test]# kubectl delete -f new-ingress.yaml --force --grace-period 0

##权重发布，根据vip用户的进行划分百分之五十
[root@server01 test]# vim new-ingress.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-release
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"   #启用Canary发布模式
    nginx.ingress.kubernetes.io/canary-by-header: "vip"   #根据HTTP请求头中的"vip"字段来决定流量分配
    nginx.ingress.kubernetes.io/canary-by-header-value: "10"   #当请求头中的"vip"字段值为"10"时，流量将被分配给新版本的服务
    nginx.ingress.kubernetes.io/canary-weight: "50"   #设置新版本服务的流量权重为50%，旧版本服务的流量权重为50%
spec:
  ingressClassName: nginx
  rules:
  - host: www.li.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: newnginxsvc
            port:
              number: 80

##永久的百分之五十（最后留的是这个）              
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-release
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "50"
spec:
  ingressClassName: nginx
  rules:
  - host: www.li.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: newnginxsvc
            port:
              number: 80
[root@server01 test]# kubectl apply -f new-ingress.yaml 
##查看详细信息
[root@server01 test]# kubectl get service
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes    ClusterIP   10.96.0.1        <none>        443/TCP   10d
newnginxsvc   ClusterIP   10.100.112.7     <none>        80/TCP    55m
nginxsvc      ClusterIP   10.100.163.120   <none>        80/TCP    56m
[root@server01 test]# kubectl describe ingress new-release 
Name:             new-release
Labels:           <none>
Namespace:        default
Address:          
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  www.li.com  
              /   newnginxsvc:80 (10.106.47.156:80,10.110.225.89:80,10.110.225.90:80)
Annotations:  nginx.ingress.kubernetes.io/canary: true
              nginx.ingress.kubernetes.io/canary-weight: 50
Events:
  Type    Reason  Age    From                      Message
  ----    ------  ----   ----                      -------
  Normal  Sync    5m39s  nginx-ingress-controller  Scheduled for sync
##访问
[root@server01 test]# curl www.li.com
old version
[root@server01 test]# curl www.li.com
new version
[root@server01 test]# curl www.li.com
new version
[root@server01 test]# curl www.li.com
old version
```





# 课后作业：金丝雀发布

service的端口号为：9090。
使用ingress金丝雀发布：当“头部消息”有vip:user，显示：[name]。否则显示“hansir”
使用ingress实现：1、访问域名[name].com，跳转到https://www.[name].com。
2、访问域名https://www.[name].com/canary/new：显示：hansir。
3、访问域名https://www.[name].com/stable/old：显示：[name]。



证书/密钥

~~~shell
##生成自签名证书，
#-openssl req: 调用 OpenSSL 工具生成证书请求。
#-x509: 指定生成的是自签名证书（X.509 格式）。
#-nodes: 表示不对私钥进行加密（不使用密码保护私钥）。
#-days 365: 指定证书的有效期为365天。
#-newkey rsa:2048: 生成一个新的 RSA 密钥，长度为 2048 位。
#-keyout ./tls.key: 将生成的私钥保存到 tls.key 文件中。
#-out ./tls.crt: 将生成的自签名证书保存到 tls.crt 文件中。
#-subj "/C=CN/ST=Beijing/L=Beijing/O=MyCompany/CN=www.lq.com": 指定证书的主题字段（Subject），包括国家（C），州（ST），城市（L），组织（O）和常用名（CN）。
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./tls.key -out ./tls.crt -subj "/C=CN/ST=Beijing/L=Beijing/O=MyCompany/CN=www.lq.com"

##在 Kubernetes 中创建包含 TLS 证书的密钥
#kubectl create secret generic: 使用 kubectl 命令创建一个通用类型的 Secret。
#lq-tls: 指定 Secret 的名称为 lq-tls。
#--from-file=tls.crt=./tls.crt: 指定从文件 tls.crt 中读取数据，并将其存储为 Secret 的 tls.crt 字段。
#--from-file=tls.key=./tls.key: 指定从文件 tls.key 中读取数据，并将其存储为 Secret 的 tls.key 字段。
#--type=kubernetes.io/tls: 指定 Secret 的类型为 kubernetes.io/tls，表示这是一个包含 TLS 证书和私钥的 Secret。
kubectl create secret generic lq-tls --from-file=tls.crt=./tls.crt --from-file=tls.key=./tls.key --type=kubernetes.io/tls

#如果证书存在，不能创建，删除再次创建即可
kubectl delete secret lq-tls

#将证书复制到/etc/pki/ca-trust/source/anchors/目录中
cp ./tls.crt /etc/pki/ca-trust/source/anchors/

#更新CA证书存储
update-ca-trust extract

#在server02,server03上创建网页目录与文件
[root@server02 ~]# mkdir -p /nginx/canary/new
[root@server02 ~]# mkdir -p /nginx/stable/old
[root@server02 ~]# echo lq > /nginx/stable/old/index.html
[root@server02 ~]# echo hansir > /nginx/canary/new/index.html
~~~

编辑部署文件

~~~shell
# 编写nginx.yaml,内含Deployment以及service的部署
[root@server01 8_2_work]# vim nginx.yaml 
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
      - name: nginx-container
        image: nginx:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf
        - name: nginx-web
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
      - name: nginx-web
        hostPath:
          path: /nginx
          type: Directory
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 9090
    targetPort: 80

## 编写conf.yaml,内含nginx配置文件
[root@server01 8_2_work]# vim conf.yaml 
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;

        location /canary/new {
            root /usr/share/nginx/html;
            index index.html;
        }

        location /stable/old {
            root /usr/share/nginx/html;
            index index.html;
        }

        location / {
            if ($http_vip = "user") {
                return 301 /stable/old;
            }
            return 301 /canary/new;
        }
    }

# 编写ingress.yaml,内含ingress策略
[root@server01 8_2_work]# vim ingress.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - www.lq.com
    secretName: lq-tls
  rules:
  - host: www.lq.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port: 
              number: 9090
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingresa
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - lq.com
    secretName: lq-tls
  rules:
  - host: lq.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port: 
              number: 9090
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite-lq
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: www.lq.com
spec:
  ingressClassName: rewrite-nginx
  rules:
  - host: "lq.com"
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: nginx
            port:
              number: 9090
~~~

部署顺序

~~~shell
[root@server01 8_2_work]# kubectl apply -f conf.yaml 
configmap/nginx-config created
[root@server01 8_2_work]# kubectl apply -f nginx.yaml 
deployment.apps/nginx-deployment created
service/nginx created
[root@server01 8_2_work]# kubectl apply -f ingress.yaml 
ingress.networking.k8s.io/nginx-ingress created
ingress.networking.k8s.io/nginx-ingresa created
ingress.networking.k8s.io/rewrite-lq created
~~~

写域名解析

~~~shell
[root@server01 8_2_work]# vim /etc/hosts 
添加
10.15.200.11 www.lq.com
10.15.200.11 lq.com
~~~

查看状态

~~~shell
kubectl get pod
kubectl get svc
kubectl get ingress
kubectl get configmaps
~~~

![image-20240804143705987](https://gitee.com/xiaojinliaqi/img/raw/master/202408041437101.png)

验证

~~~shell
curl -L https://www.lq.com/canary/old/
curl -L https://www.lq.com/stable/old/
curl -L https://www.lq.com/canary/new/
curl -L www.lq.com/stable/old/
curl -L www.lq.com/canary/new/
curl -L lq.com/canary/new/
curl -L lq.com/stable/old/
curl -L -H"vip:user" lq.com
curl -L -H"vip:user" www.lq.com
curl -L -H"vip:user" https://www.lq.com
~~~

![image-20240804144329421](https://gitee.com/xiaojinliaqi/img/raw/master/202408041443470.png)

![image-20240804144354402](https://gitee.com/xiaojinliaqi/img/raw/master/202408041443448.png)
