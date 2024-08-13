# Deployment应用的滚动更新

![image-20240729195242182](https://gitee.com/xiaojinliaqi/img/raw/master/202407291952470.png)

~~~shell
[root@server01 ~]# vim nginx.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
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
[root@server01 ~]# kubectl apply -f nginx.yaml 
deployment.apps/web created
[root@server01 ~]# kubectl get pod
NAME                  READY   STATUS    RESTARTS   AGE
web-8588484f4-7zmc8   1/1     Running   0          4s
web-8588484f4-ldzpm   1/1     Running   0          4s
web-8588484f4-mwnfs   1/1     Running   0          4s
~~~

