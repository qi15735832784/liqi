# Job与cronJob

## job

#restartPolicy: Never/Onfailure
#backoffLimit: 3：失败之后，重启的次数
#activeDeadlineSeconds: 120：设置此job总结书时间
#ttlSecondsAfterFinished: 30：设置此job完成或失败后的删除延迟时间
#parallelism: 2：并行执行两个
#completions: 10：执行总量
#completionMode: Indexed（显示索引）/ Nonlndexed（默认值）

## CronJob

#timeZone: Asia/Shanghai：Ect/UTC 设置时区
#successfulJobsHistoryLimit: 3：记录成功次数3
#failedJobsHistoryLimit: 3：记录失败次数3
#startingDeadlineSeconds: 120：最晚执行时间
#concurrencyPolicy: Allow：允许叠加   Forbid忽略旧任务  Replace忽略新任务
#suspend: true：挂起不要执行   false接触挂起，继续执行



job的实验配置

~~~shell
[root@server01 ~]# vim myjob.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: lijob
spec:
  template:
    spec:
      containers:
      - name: lijob
        image: busybox:1.36
        imagePullPolicy: IfNotPresent
        command:
        - /bin/sh
        - -c
        - echo "hello lisir, hi k8s1"
[root@server01 ~]# kubectl apply -f myjob.yaml 
#这是一个 Kubernetes Job 配置的错误。错误发生在 Job 的规格（spec）中，具体是在 template.spec.restartPolicy 字段。restartPolicy（重启策略）是必填字段，但在你的配置中可能没有设置或设置了不正确的值。对于 Kubernetes Job，restartPolicy 只能设置为两个值之一："OnFailure"：如果 Pod 失败，Job 会尝试重新运行它。"Never"：如果 Pod 失败，Job 不会尝试重新运行它。普通 Pod 默认的 restartPolicy 值 "Always" 对 Job 来说是无效的。
The Job "lijob" is invalid: spec.template.spec.restartPolicy: Required value: valid values: "OnFailure", "Never"

##重新编辑myjob文件
[root@server01 ~]# vim myjob.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: lijob
spec:
0  template:
    spec:
      restartPolicy: Never   #Kubernetes 不会在你的 Job 的 Pod 失败后重新启动它
      containers:
      - name: lijob
        image: busybox:1.36
        imagePullPolicy: IfNotPresent
        command:
        - /bin/sh
        - -c
        - echo "hello lisir, hi k8s1"
[root@server01 ~]# kubectl apply -f myjob.yaml 
job.batch/lijob created
[root@server01 ~]# kubectl get pod
NAME          READY   STATUS      RESTARTS   AGE
lijob-whjst   0/1     Completed   0          12s
[root@server01 ~]# kubectl logs lijob-whjst 
hello lisir, hi k8s1
[root@server01 ~]# kubectl describe jobs.batch lijob 
Name:             lijob   #这个 Job 的名称
Namespace:        default   #Job 所在的命名空间
Selector:         batch.kubernetes.io/controller-uid=232d5117-69c2-4fac-a89e-f1ddf321e6ee   #用于标识与这个 Job 相关的 Pod
Labels:           batch.kubernetes.io/controller-uid=232d5117-69c2-4fac-a89e-f1ddf321e6ee   #识 Job 和 Pod，方便管理和查找
                  batch.kubernetes.io/job-name=lijob
                  controller-uid=232d5117-69c2-4fac-a89e-f1ddf321e6ee
                  job-name=lijob
Annotations:      <none>   #表示这个 Job 没有附加任何注释
Parallelism:      1   #同时运行的 Pod 数量
Completions:      1   #需要成功完成的 Pod 数量
Completion Mode:  NonIndexed   #示 Job 的完成状态不会被索引
Suspend:          false   #Job 未被暂停
Backoff Limit:    6   #失败重试的最大次数
Start Time:       Wed, 31 Jul 2024 16:16:46 +0800   #开始时间
Completed At:     Wed, 31 Jul 2024 16:16:51 +0800   #完成时间
Duration:         5s   #Job 运行持续时间
Pods Statuses:    0 Active (0 Ready) / 1 Succeeded / 0 Failed  #显示 Job 相关的 Pod 状态
0 Active (0 Ready): 当前没有活跃的 Pod
1 Succeeded: 1 个 Pod 成功完成
0 Failed: 没有失败的 Pod

[root@server01 ~]# vim myjob.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: lijob
spec:
  backoffLimit: 3
  activeDeadlineSeconds: 120
  ttlSecondsAfterFinished: 30
  parallelism: 2
  completions: 10
  completionMode: Indexed
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: lijob
        image: busybox:1.36
        imagePullPolicy: IfNotPresent
        command:
        - /bin/sh
        - -c
        - echo "hello lisir, hi k8s1"
[root@server01 ~]# kubectl apply -f myjob.yaml 
job.batch/lijob created
[root@server01 ~]# kubectl get pod -w
[root@server01 ~]# kubectl get pod
[root@server01 ~]# kubectl delete -f myjob.yaml 
job.batch "lijob" deleted


~~~

[关于crontab工具的网站](https://crontab.guru/ 'https://crontab.guru/')

表示“每”：分钟 0/1 其他停留在上一级

Cronjob的实验配置

~~~shell
[root@server01 ~]# vim mcjob.yaml 
apiVersion: batch/v1
kind: CronJob
metadata: 
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: hello
            image: busybox:1.36
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - date +%T; echo hello lisir
[root@server01 ~]# kubectl get pod
NAME                   READY   STATUS      RESTARTS   AGE
hello-28706931-6x7z4   0/1     Completed   0          90s
hello-28706932-fffvb   0/1     Completed   0          29s 
[root@server01 ~]# kubectl logs hello-28706931-6x7z4 
08:51:06
hello lisir
[root@server01 ~]# kubectl logs hello-28706932-fffvb 
08:52:06
hello lisir
[root@server01 ~]# kubectl get cronjobs.batch 
NAME    SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello   */1 * * * *   <none>     False     0        27s             3m12s
[root@server01 ~]# kubectl edit cronjobs.batch 
修改此处suspend: true
[root@server01 ~]# kubectl get cronjobs.batch 
NAME    SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello   */1 * * * *   <none>     True      0        73s             7m58s
##查询当前时间
[root@server01 ~]# timedatectl show
Timezone=Asia/Shanghai
LocalRTC=no
CanNTP=yes
NTP=yes
NTPSynchronized=yes
TimeUSec=Wed 2024-07-31 16:59:55 CST
RTCTimeUSec=Wed 2024-07-31 16:59:55 CST
[root@server01 ~]# kubectl delete -f mcjob.yaml 

[root@server01 ~]# vim mcjob.yaml 
apiVersion: batch/v1
kind: CronJob
metadata: 
  name: hello
spec:
  timeZone: Asia/Shanghai   #使用上海时区
  successfulJobsHistoryLimit: 3   #保留最近 3 个成功的 Job 历史记录
  failedJobsHistoryLimit: 3   #保留最近 3 个失败的 Job 历史记录
  startingDeadlineSeconds: 120   #如果 Job 未能在预定时间后 120 秒内开始，则视为失败
  concurrencyPolicy: Allow   #允许多个 Job 同时运行
  schedule: "*/1 * * * *"   #每分钟运行一次
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure   #如果 Pod 失败，则重新启动
          containers:
          - name: hello
            image: busybox:1.36
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - date +%T; echo hello lisir
[root@server01 ~]# kubectl apply -f mcjob.yaml 
[root@server01 ~]# kubectl get pod -w
[root@server01 ~]# kubectl logs hello-28706943-7cgdp 
09:02:59
hello lisir
[root@server01 ~]# kubectl logs hello-28706944-wt4gs 
09:04:04
hello lisir
[root@server01 ~]# kubectl get pod
NAME                   READY   STATUS      RESTARTS   AGE
hello-28706943-7cgdp   0/1     Completed   0          2m47s
hello-28706944-wt4gs   0/1     Completed   0          107s
hello-28706945-6gsxd   0/1     Completed   0          41s
[root@server01 ~]# kubectl get pod
NAME                   READY   STATUS      RESTARTS   AGE
hello-28706946-tmttb   0/1     Completed   0          2m11s
hello-28706947-fnnf9   0/1     Completed   0          77s
hello-28706948-64fkc   0/1     Completed   0          12s
[root@server01 ~]# kubectl delete -f mcjob.yaml 
~~~



# StatefulSet有状态发部署与灰度状态

有状态数据：比如：mysql 的存储，程序的API等等

statefulset：

1. 稳定的，唯一网络标识
	- 不重复且由大到小，0起始
	- 期望值重新创建的 pod id 不变，ip 变化
	- 由DNS实现：[pod-Name].[service-Name].[namespace]
2. 稳定的，持久的存储(volume)
3. 有序的，优雅的部署和扩缩
	- 扩展由小到大，受到 minReadySeconds 的影响
	- 收缩由大到小，/删除时 不受 minReadySeconds 的影响
4. 有序的，自动的滚动更新
	- rollingUpdate：由大到小更新
	- patition：保护的副本，不受到滚动更新和回滚的影响
	- patition：只能减少归零之后在增大，否则将有多个版本的副本

实验部分

~~~shell
[root@server01 ~]# vim ssweb.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 6
  minReadySeconds: 5
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
        - name: web
          containerPort: 80
[root@server01 ~]# kubectl apply -f ssweb.yaml 
service/nginx created
statefulset.apps/web created
[root@server01 ~]# kubectl get pod -w
~~~



~~~shell
##唯一标识，重复且由大到小，0起始
[root@server01 ~]# kubectl get pod
NAME    READY   STATUS    RESTARTS   AGE
web-0   1/1     Running   0          70s
web-1   1/1     Running   0          60s
web-2   1/1     Running   0          50s
web-3   1/1     Running   0          40s
web-4   1/1     Running   0          30s
web-5   1/1     Running   0          25s
[root@server01 ~]# kubectl infopod 
NAME    IP              NODE       IMAGE
web-0   10.106.47.133   server03   nginx:latest
web-1   10.110.225.79   server02   nginx:latest
web-2   10.106.47.134   server03   nginx:latest
web-3   10.110.225.81   server02   nginx:latest
web-4   10.106.47.138   server03   nginx:latest
web-5   10.110.225.82   server02   nginx:latest 
[root@server01 ~]# kubectl get statefulsets.apps 
NAME   READY   AGE
web    6/6     2m5s
~~~



~~~shell
##期望值重新创建的 pod id 不变，ip 变化
[root@server01 ~]# kubectl infopod 
NAME    IP              NODE       IMAGE
web-0   10.106.47.133   server03   nginx:latest
web-1   10.110.225.79   server02   nginx:latest
web-2   10.106.47.134   server03   nginx:latest
web-3   10.110.225.81   server02   nginx:latest
web-4   10.106.47.138   server03   nginx:latest
web-5   10.110.225.82   server02   nginx:latest
[root@server01 ~]# kubectl delete pod web-3
pod "web-3" deleted
[root@server01 ~]# kubectl infopod 
NAME    IP              NODE       IMAGE
web-0   10.106.47.133   server03   nginx:latest
web-1   10.110.225.79   server02   nginx:latest
web-2   10.106.47.134   server03   nginx:latest
web-3   10.110.225.84   server02   nginx:latest
web-4   10.106.47.138   server03   nginx:latest
web-5   10.110.225.82   server02   nginx:latest
~~~



~~~shell
##扩展由小到大，受到 minReadySeconds 的影响
[root@server01 ~]# kubectl scale statefulset web  --replicas 10
[root@server01 ~]# kubectl get pod -w
NAME    READY   STATUS    RESTARTS   AGE
web-0   1/1     Running   0          10m
web-1   1/1     Running   0          10m
web-2   1/1     Running   0          10m
web-3   1/1     Running   0          2m31s
web-4   1/1     Running   0          9m47s
web-5   1/1     Running   0          9m42s
web-6   1/1     Running   0          7s
web-7   0/1     Pending   0          0s
web-7   0/1     Pending   0          0s
web-7   0/1     ContainerCreating   0          0s
web-7   0/1     ContainerCreating   0          0s
web-7   1/1     Running             0          1s
web-8   0/1     Pending             0          0s
web-8   0/1     Pending             0          0s
web-8   0/1     ContainerCreating   0          0s
web-8   0/1     ContainerCreating   0          0s
web-8   1/1     Running             0          1s
web-9   0/1     Pending             0          0s
web-9   0/1     Pending             0          0s
web-9   0/1     ContainerCreating   0          0s
web-9   0/1     ContainerCreating   0          0s
web-9   1/1     Running             0          1s
~~~







~~~shell
##收缩由大到小，/删除时 不受 minReadySeconds 的影响
[root@server01 ~]# kubectl scale statefulset web  --replicas 3
[root@server01 ~]# kubectl get pod -w
NAME    READY   STATUS        RESTARTS   AGE
web-0   1/1     Running       0          12m
web-1   1/1     Running       0          12m
web-2   1/1     Running       0          12m
web-3   1/1     Running       0          4m25s
web-4   1/1     Running       0          11m
web-5   1/1     Running       0          11m
web-6   1/1     Running       0          2m1s
web-7   1/1     Running       0          111s
web-8   0/1     Terminating   0          101s
web-8   0/1     Terminating   0          101s
web-8   0/1     Terminating   0          101s
web-7   1/1     Terminating   0          111s
web-7   1/1     Terminating   0          111s
web-7   0/1     Terminating   0          111s
web-7   0/1     Terminating   0          111s
web-7   0/1     Terminating   0          111s
web-7   0/1     Terminating   0          111s
web-6   1/1     Terminating   0          2m2s
web-6   1/1     Terminating   0          2m2s
web-6   0/1     Terminating   0          2m2s
web-6   0/1     Terminating   0          2m2s
web-6   0/1     Terminating   0          2m2s
web-6   0/1     Terminating   0          2m2s
web-5   1/1     Terminating   0          11m
web-5   1/1     Terminating   0          11m
web-5   0/1     Terminating   0          11m
web-5   0/1     Terminating   0          11m
web-5   0/1     Terminating   0          11m
web-5   0/1     Terminating   0          11m
web-4   1/1     Terminating   0          11m
web-4   1/1     Terminating   0          11m
web-4   0/1     Terminating   0          11m
web-4   0/1     Terminating   0          11m
web-4   0/1     Terminating   0          11m
web-4   0/1     Terminating   0          11m
web-3   1/1     Terminating   0          4m28s
web-3   1/1     Terminating   0          4m29s
web-3   0/1     Terminating   0          4m29s
web-3   0/1     Terminating   0          4m29s
web-3   0/1     Terminating   0          4m29s
web-3   0/1     Terminating   0          4m29s
~~~



~~~shell
##由DNS实现：[pod-Name].[service-Name].[namespace]
[root@server01 ~]# kubectl get pod
NAME    READY   STATUS    RESTARTS   AGE
web-0   1/1     Running   0          17m
web-1   1/1     Running   0          17m
web-2   1/1     Running   0          16m
[root@server01 ~]# kubectl exec -it web-0 -- bash
root@web-0:/# hostname
web-0
root@web-0:/# exit
exit
[root@server01 ~]# kubectl exec -it web-1 -- bash
root@web-1:/# hostname
web-1
[root@server01 ~]# kubectl run -it --image busybox:1.28 dnstest --restart Never --rm
If you don't see a command prompt, try pressing enter.
/ # nslookup web-0.nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-0.nginx
Address 1: 10.106.47.133 web-0.nginx.default.svc.cluster.local
[root@server01 ~]# kubectl delete -f ssweb.yaml 
service "nginx" deleted
statefulset.apps "web" deleted
~~~



~~~shell
##手动更新
[root@server01 ~]# vim ssweb.yaml  
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  updateStrategy:
    type: OnDelete
  serviceName: "nginx"
  replicas: 3
  # minReadySeconds: 5
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
        - name: web
          containerPort: 80
[root@server01 ~]# kubectl apply -f ssweb.yaml 
service/nginx created
statefulset.apps/web created
[root@server01 ~]# kubectl patch statefulsets.apps web --type='json' -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"nginx:1.22"}]'
statefulset.apps/web patched
[root@server01 ~]# kubectl infopod 
NAME    IP              NODE       IMAGE
web-0   10.106.47.136   server03   nginx:latest
web-1   10.110.225.87   server02   nginx:latest
web-2   10.110.225.88   server02   nginx:latest
[root@server01 ~]# kubectl infopod 
NAME    IP              NODE       IMAGE
web-0   10.106.47.136   server03   nginx:latest
web-1   10.110.225.87   server02   nginx:latest
web-2   10.110.225.88   server02   nginx:latest
[root@server01 ~]# kubectl delete pod web-1
pod "web-1" deleted
[root@server01 ~]# kubectl infopod 
NAME    IP              NODE       IMAGE
web-0   10.106.47.136   server03   nginx:latest
web-1   10.110.225.90   server02   nginx:1.22
web-2   10.110.225.88   server02   nginx:latest
~~~



~~~shell
##标准的滚动更新
[root@server01 ~]# vim ssweb.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  updateStrategy:
    type: RollingUpdate
  serviceName: "nginx"
  replicas: 10
  # minReadySeconds: 5
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
        - name: web
          containerPort: 80
[root@server01 ~]# kubectl apply -f ssweb.yaml 
[root@server01 ~]# kubectl infopod 
NAME    IP              NODE       IMAGE
web-0   10.106.47.141   server03   nginx:latest
web-1   10.110.225.92   server02   nginx:latest
web-2   10.110.225.91   server02   nginx:latest
web-3   10.106.47.142   server03   nginx:latest
web-4   10.106.47.143   server03   nginx:latest
web-5   10.110.225.93   server02   nginx:latest
web-6   10.110.225.94   server02   nginx:latest
web-7   10.106.47.144   server03   nginx:latest
web-8   10.110.225.95   server02   nginx:latest
web-9   10.106.47.145   server03   nginx:latest
[root@server01 ~]#  kubectl patch statefulsets.apps web --type='json' -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"nginx:1.24"}]'
[root@server01 ~]# kubectl infopod 
NAME    IP               NODE       IMAGE
web-0   10.106.47.150    server03   nginx:1.24
web-1   10.110.225.100   server02   nginx:1.24
web-2   10.110.225.99    server02   nginx:1.24
web-3   10.106.47.149    server03   nginx:1.24
web-4   10.106.47.148    server03   nginx:1.24
web-5   10.110.225.98    server02   nginx:1.24
web-6   10.110.225.97    server02   nginx:1.24
web-7   10.106.47.147    server03   nginx:1.24
web-8   10.110.225.96    server02   nginx:1.24
web-9   10.106.47.146    server03   nginx:1.24
[root@server01 ~]# kubectl patch statefulsets.apps web -p '{"spec":{"updateStrategy":{"type":"RollingUpdate","rollingUpdate":{"partition":7}}}}'
[root@server01 ~]# kubectl infopod 
NAME    IP               NODE       IMAGE
web-0   10.106.47.150    server03   nginx:1.24
web-1   10.110.225.100   server02   nginx:1.24
web-2   10.110.225.99    server02   nginx:1.24
web-3   10.106.47.149    server03   nginx:1.24
web-4   10.106.47.148    server03   nginx:1.24
web-5   10.110.225.98    server02   nginx:1.24
web-6   10.110.225.97    server02   nginx:1.24
web-7   10.106.47.147    server03   nginx:1.24
web-8   10.110.225.96    server02   nginx:1.24
web-9   10.106.47.146    server03   nginx:1.24
[root@server01 ~]#  kubectl patch statefulsets.apps web --type='json' -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"nginx:1.22"}]'
statefulset.apps/web patched
[root@server01 ~]# kubectl get pod -w
NAME    READY   STATUS    RESTARTS   AGE
web-0   1/1     Running   0          7m7s
web-1   1/1     Running   0          7m10s
web-2   1/1     Running   0          7m14s
web-3   1/1     Running   0          7m17s
web-4   1/1     Running   0          7m20s
web-5   1/1     Running   0          7m24s
web-6   1/1     Running   0          7m27s
web-7   1/1     Running   0          7s
web-8   1/1     Running   0          10s
web-9   1/1     Running   0          14s
[root@server01 ~]# kubectl infopod 
NAME    IP               NODE       IMAGE
web-0   10.106.47.150    server03   nginx:1.24
web-1   10.110.225.100   server02   nginx:1.24
web-2   10.110.225.99    server02   nginx:1.24
web-3   10.106.47.149    server03   nginx:1.24
web-4   10.106.47.148    server03   nginx:1.24
web-5   10.110.225.98    server02   nginx:1.24
web-6   10.110.225.97    server02   nginx:1.24
web-7   10.106.47.152    server03   nginx:1.22
web-8   10.110.225.101   server02   nginx:1.22
web-9   10.106.47.151    server03   nginx:1.22
~~~



~~~shell
[root@server01 ~]# vim ssweb.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  podManagementPolicy: Parallel
  updateStrategy:
    type: RollingUpdate
  serviceName: "nginx"
  replicas: 10
  # minReadySeconds: 5
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
        - name: web
          containerPort: 80
[root@server01 ~]# kubectl apply -f ssweb.yaml 
service/nginx created
statefulset.apps/web created
[root@server01 ~]# kubectl get pod
NAME    READY   STATUS    RESTARTS   AGE
web-0   1/1     Running   0          54s
web-1   1/1     Running   0          53s
web-2   1/1     Running   0          53s
web-3   1/1     Running   0          53s
web-4   1/1     Running   0          53s
web-5   1/1     Running   0          53s
web-6   1/1     Running   0          53s
web-7   1/1     Running   0          53s
web-8   1/1     Running   0          53s
web-9   1/1     Running   0          53s

~~~

###看到第八天的第三个视频的23分钟







# 课后作业

下面是用service做分离的lnmp环境：

1、在namespace default中使用Deployment部署pod 3个 运行nginx，使用service 端口映射到clusterIP的8080端口

2、在namespace devtest中 使用Statefulset部署pod 3个 运行PHP，使用service 的clusterIP访问。

3、在namespace opstest中，使用Statefulset部署pod 1个运行mysql，访问nginx的service的clusterIP地址，可以打开index.php的测试页面，及mysql的链接测试。

4、ingress-nginx安装正确

[作业地址](https://gitee.com/zhaojiedong/work/blob/master/%E7%AC%94%E8%AE%B0/7_31%E4%BD%9C%E4%B8%9A.md 'https://gitee.com/zhaojiedong/work/blob/master/%E7%AC%94%E8%AE%B0/7_31%E4%BD%9C%E4%B8%9A.md')

[第四题仓库](https://gitee.com/zhaojiedong/work/blob/master/%E7%AC%94%E8%AE%B0/%E5%AE%89%E8%A3%85%20Ingress.md 'https://gitee.com/zhaojiedong/work/blob/master/%E7%AC%94%E8%AE%B0/%E5%AE%89%E8%A3%85%20Ingress.md')



