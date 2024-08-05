# 资源限制与QOS

![image-20240805171945652](https://gitee.com/xiaojinliaqi/img/raw/master/202408051719866.png)



超卖：limit 可以，requests 不可以，cpu可以，memory不可以
requests 小于 limits = Burstable
requests 等于 limits = Guaranteed
requests 和 limits  没有设置 = BestEffort

###### LimitRange:

避免用户配置每个容器，已 namespace 为单位
1.指定能给容器配置的每种资源的最大和最小限制
2.没有设置的资源限制的容器，设置默认限制

##### serviceaccount:

在 kubernets 中有两种账户：
1.用于登录 kubernetes 的
2.sa 用来创建 pod 的



~~~shell
vim pod.yaml
###
apiVersion: v1   #Kubernetes API 的版本，这里使用的是 v1 版本
kind: Pod   #定义对象类型，这里是 Pod，表示要创建一个 Pod
metadata:   #元数据部分，包含 Pod 的名称和其他信息
  name: req-box-1   #Pod 的名称，这里为 req-box-1
spec:   #Pod 的规格，定义了 Pod 的内容和行为
  containers:   #Pod 中运行的容器列表
  - name: main   #容器的名称，这里为 main
    image: busybox:1.36   #使用的容器镜像，这里是 busybox:1.36，表示使用 BusyBox 工具箱的特定版本
    imagePullPolicy: IfNotPresent   #容器镜像拉取策略，这里设置为 IfNotPresent，表示只有在本地不存在时才从远程仓库拉取
    command: ["sleep","1d"]   #容器启动时执行的命令，这里是 sleep 1d，表示容器将休眠 1 天（24 小时）
    resources:   #容器的资源需求配置
      requests:   #定义容器所需的资源量
        cpu: 200m   #CPU 请求量，设置为 200m，表示 0.2 个 CPU 核心
        memory: 10Mi   #内存请求量，设置为 10Mi，表示 10 Mebibytes（MiB）的内存（大约 10.5 MB）

~~~



