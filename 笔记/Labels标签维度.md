# Labels标签维度

```test
基于应用的横向维度（不同的POD有不同的标签）
基于版本的纵向维度（同一个POD 有不同的版本）
```

![image-20240727162608178](https://gitee.com/xiaojinliaqi/img/raw/master/202407271626424.png)

```test
key：必须小于63字符，不许字母和字符开头结尾  可以包含_. 字母和数字
Key+value不得超过253个字符
```

查询标签

```shell
[root@server01 ~]# kubectl get nodes --show-labels 
NAME       STATUS   ROLES           AGE     VERSION   LABELS
server01   Ready    control-plane   4d18h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server01,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
server02   Ready    <none>          4d17h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server02,kubernetes.io/os=linux
server03   Ready    <none>          4d17h   v1.30.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=server03,kubernetes.io/os=linux
```

label：

[DomainName] / [Key] = [Value]
Kubernetes.io \ k8s.io 表示系统标签，尽量不要更改（操作系统加进来的）