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

# 课后作业

使用 deployment 部署pod，启动DNS服务，解析对应的域名。
解析https://www.k8shan.com完成以下内容：
1 访问域名 https://www.k8shan.com：显示：test good。
2 所有的pod均可以自动弹性伸缩
3 所有 pod 均不可被系统驱离
4 内存不得超过 100Mi CPU 不得超过 500 豪核

实验步骤

~~~shell
# 前提是deploy.yaml，components.yaml这两yaml文件部署好
[root@server01 ~]# mkdir 8_5_work
[root@server01 ~]# cd 8_5_work/
# 生成证书密钥
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./k8s.key -out ./k8s.crt -subj "/CN=www.k8slq.com"
# 导入证书
cp k8s.crt /etc/pki/ca-trust/source/anchors/
# 刷新证书
update-ca-trust
# 创建证书密钥secret
kubectl create secret tls nginx-tls --key k8s.key --cert
# 在server02,server03创建网页
mkdir /html
echo "test good" > /html/index.html
# 编辑default.conf，nginx.conf这两配置文件
[root@server01 8_5_work]# vim nginx.conf 

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  512;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
[root@server01 8_5_work]# vim default.conf 
server {
    listen       443 ssl;
    server_name  www.k8slq.com;
    ssl_certificate /etc/nginx/ssl/tls.crt;
    ssl_certificate_key /etc/nginx/ssl/tls.key;
    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
# 创建configmap
kubectl create configmap webconf --from-file default.conf 
# 编写nginx,yaml,ingress.yaml,hpa.yaml这三个文件 
[root@server01 8_5_work]# cat nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 443
        resources:
          limits:
            cpu: 500m
            memory: 100Mi
          requests:
            cpu: 500m
            memory: 100Mi
        volumeMounts:
        - name: nginx-html
          mountPath: /usr/share/nginx/html/
        - name: web
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
        - name: tls
          mountPath: /etc/nginx/ssl/
          readOnly: true
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Equal"
        effect: "NoSchedule"
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
      volumes:
      - name: web
        configMap:
          name: webconf
      - name: tls
        secret:
          secretName: nginx-tls
      - name: nginx-html
        hostPath:
          path: /html
[root@server01 8_5_work]# cat ingress.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "https"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - www.k8slq.com
    secretName: nginx-tls
  rules:
  - host: www.k8slq.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port: 
              number: 443
[root@server01 8_5_work]# cat hpa.yaml 
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 120
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
# 开始部署
kubectl apply -f ./
# 写入域名解析
vim /etc/hosts
添加：10.15.200.11 www.k8slq.com
~~~

验证

~~~shell
curl https://www.k8slq.com
~~~

![image-20240805214412382](https://gitee.com/xiaojinliaqi/img/raw/master/202408052144446.png)

查看容器限制

```
kubectl describe deployments.apps web-deployment
```

![image-20240805214607218](https://gitee.com/xiaojinliaqi/img/raw/master/202408052146274.png)

验证是否扩缩

```
# 监控 pod 数量变化
watch -n 1 "kubectl get pods"
# 给予压力
kubectl exec -it web-deployment-6b9bf69d6b-k2qp4 -- dd if=/dev/zero of=/dev/null
# 只需等待
```

![image-20240805214706160](https://gitee.com/xiaojinliaqi/img/raw/master/202408052147208.png)

~~~test
时间最大的两个 pod 为最初的 pod，其余 pod 则是由于 cpu 压力过大，hpa 新开的 pod 停止给予 cpu 压力后，等待 2 分钟，看到 pod 数量缩减至 2 个
~~~

![image-20240805214824146](https://gitee.com/xiaojinliaqi/img/raw/master/202408052148191.png)

查看 pod 是否无法被驱离

```
kubectl describe pods web-deployment-6b9bf69d6b-tsvb2
```

![image-20240805214849615](https://gitee.com/xiaojinliaqi/img/raw/master/202408052148666.png)



