# 综合实验



### config and secret  Tips:

1. 引用的 key 必须存在
2. envFrom calueFrom 无法热更新
3. envFrom 配置环境环境变量，如果key 是无效的，它会忽略key
4. configmap 和 secret 必须要和pod 的引用在相同的 namespace 中
5. subPath 也无法热更新
6. configmap 和secret 尽量都小于 1MB

## 使用  secret 管理 https 的证书

~~~shell
[root@server01 ~]# mkdir secret
[root@server01 ~]# cd secret/
[root@server01 secret]# ls
[root@server01 secret]# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=www.lq.com"
[root@server01 secret]# kubectl create secret tls nginx-test-tls --key tls.key --cert tls.crt
[root@server01 secret]# kubectl run web --image nginx:latest --image-pull-policy IfNotPresent
[root@server01 secret]# kubectl exec web -- cat /etc/nginx/nginx.conf > nginx.conf
[root@server01 secret]# kubectl exec web -- cat /etc/nginx/conf.d/default.conf > default.conf
[root@server01 secret]# vim nginx.conf 
#10行修改为512

[root@server01 secret]# vim default.conf
按文件所需的修改
server {
    listen       443 ssl;
    server_name  www.lq.com;

    ssl_certificate /etc/nginx/ssl/tls.crt;
    ssl_certificate_key /etc/nginx/ssl/tls.key;

    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded_For $proxy_add_x_forwarded_for;
    }
[root@server01 secret]# kubectl create configmap webconfig --from-file ./default.conf 
[root@server01 secret]# kubectl create configmap nginxconfig --from-file ./nginx.conf 

##`ConfigMap` 对象的详细信息输出，来自 Kubernetes。`ConfigMap` 用于存储配置信息，这些信息可以被挂载到容器中或者作为环境变量使用
- **服务器配置**：
    
    - `listen 443 ssl;`：Nginx 监听 443 端口，并启用 SSL。
    - `server_name www.lq.com;`：服务器名称为 `www.lq.com`。
    - `ssl_certificate` 和 `ssl_certificate_key`：指定 SSL 证书和私钥的位置。
- **位置配置**：
    
    - `location / {}`：处理根路径的请求。
        - `root /usr/share/nginx/html;`：指定请求的根目录。
        - `index index.html index.htm;`：指定默认的索引文件。
        - `proxy_set_header`：设置 HTTP 头部，用于将请求的主机、真实 IP 和转发的 IP 传递给后端服务。
[root@server01 secret]# kubectl describe configmaps webconfig 
~~~
![image.png](https://gitee.com/xiaojinliaqi/img/raw/master/202408051411210.png)

#编写 nginx. yaml 文件
```shell
vim nginx.yaml
###
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
        image: nginx:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: web
###
#部署nginx
kubectl apply -f nginx.yaml

#列出当前 Kubernetes 集群中所有的服务。输出通常包括每个服务的名称、命名空间、类型、Cluster IP、外部 IP、端口和其他相关信息
[root@server01 secret]# kubectl get service
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)            AGE
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP            13d
nginxsvc     ClusterIP   10.100.69.80   <none>        8080/TCP,443/TCP   6m24s

#添加地址解析，IP地址是nginxsvc的ip
vim /etc/hosts
添加：10.100.69.80 www.lq.com

访问curl
curl --cacert tls.crt https://www.lq.com/
```
![image.png](https://gitee.com/xiaojinliaqi/img/raw/master/202408051438169.png)

进容器查看配置文件是否更新 （热更新）
![image.png](https://gitee.com/xiaojinliaqi/img/raw/master/202408051442997.png)

## 使用  ingress 做代理访问

编辑 web-ingress. yaml 文件
```shell
vim web-ingress.yaml
###
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "https"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: www.lq.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginxsvc
            port:
              number: 443
  tls:
  - hosts:
    - www.lq.com
    secretName: nginx-test-tls
```
部署
```shell
kubectl apply -f web-ingress.yaml
```
修改地址解析 （IP 是安装 ingress 的那台主机）
```shell
vim /etc/hosts
添加：10.15.200.11 www.lq.com
```

curl 访问
```shell
curl --cacert tls.crt https://www.lq.com
```
![image.png](https://gitee.com/xiaojinliaqi/img/raw/master/202408051457707.png)
