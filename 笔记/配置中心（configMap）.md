# 配置中心（configMap）

配置文件中的内容全是key value结构

局限性：单个配置文件不能大于1MB，如果大于1MB只能以挂载的方式使用

1. 通过变量文件写入
2. 通过volume卷存入



~~~shell
[root@server01 ~]# mkdir 8_2
[root@server01 ~]# cd 8_2/
[root@server01 8_2]# ls
[root@server01 8_2]# kubectl get configmaps 
NAME               DATA   AGE
kube-root-ca.crt   1      10d
[root@server01 8_2]# kubectl create configmap tomcat-config --from-literal tomcat_port=8080 --from-literal server_name=my.tomcat.com
configmap/tomcat-config created
[root@server01 8_2]# kubectl get configmaps 
NAME               DATA   AGE
kube-root-ca.crt   1      10d
tomcat-config      2      3s
[root@server01 8_2]# kubectl describe configmaps tomcat-config 
Name:         tomcat-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
tomcat_port:
----
8080
server_name:
----
my.tomcat.com

BinaryData
====

Events:  <none>
[root@server01 8_2]# kubectl get configmaps tomcat-config -o yaml
apiVersion: v1
data:
  server_name: my.tomcat.com
  tomcat_port: "8080"
kind: ConfigMap
metadata:
  creationTimestamp: "2024-08-02T02:02:21Z"
  name: tomcat-config
  namespace: default
  resourceVersion: "88829"
  uid: 907c7adb-eae5-4944-9fcd-7b4f6a8fd986



~~~

