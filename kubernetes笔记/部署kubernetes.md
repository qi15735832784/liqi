# 部署kubernetes

---

三台节点部署kubernetes

~~~shell
[root@server01 ~]# iptables -F
[root@server01 ~]# iptables-save 
[root@server01 ~]# systemctl stop firewalld
[root@server01 ~]# systemctl disable firewalld
[root@server01 ~]# vim /etc/selinux/config
修改为disabled
~~~

![image-20240725155823103](https://gitee.com/xiaojinliaqi/img/raw/master/202407251558194.png)

设置域名解析

~~~
10.15.200.11 server01
10.15.200.12 server02
10.15.200.13 server03
~~~

![image-20240725160002269](https://gitee.com/xiaojinliaqi/img/raw/master/202407251600314.png)

~~~shell
#将域名解析拷贝到server02,server03
[root@server01 ~]# scp /etc/selinux/config server02:/etc/selinux/config
[root@server01 ~]# scp /etc/selinux/config server03:/etc/selinux/config
~~~

重启完验证

~~~shell
#重启
[root@server01 ~]# init 6
#验证
[root@server01 ~]# setenforce 0
[root@server01 ~]# getenforce
~~~

~~~shell
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
##表示网络桥接处理数据包调用 ipv4 的 iptables 进行过滤处理，保证桥连接卡的数据包可以按照iptables 规则处理，比如NAT
net.bridge.bridge-nf-call-iptables  = 1
##表示网络桥接处理数据包调用 ipv6 的 iptables 进行处理
net.bridge.bridge-nf-call-ip6tables = 1
##表示打开主机的路由转发（不同网段可以互相转发数据）
net.ipv4.ip_forward                 = 1

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
~~~

安装必要软件

~~~shell
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3
sudo sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
# Step 4: 更新并安装Docker-CE
sudo yum makecache
# dnf install containerd.io -y
#查看安装版本
[root@server01 ~]# containerd -v
containerd containerd.io 1.7.19 2bf793ef6dc9a18e00cb12efb64355c2c9d5eb41
#处理化操作
[root@server01 ~]# containerd config default | sudo tee /etc/containerd/config.toml
#主节点配置，另外两个节点scp就可以
[root@server01 ~]# vim /etc/containerd/config.toml
~~~

#67行引号里面修改registry.aliyuncs.com/google_containers/pause:3.9

![image-20240725160603522](https://gitee.com/xiaojinliaqi/img/raw/master/202407251606557.png)

#139行等号后面改为true

 ![](https://gitee.com/xiaojinliaqi/img/raw/master/202407251607833.png)

~~~shell
#镜像仓库
[root@server01 ~]# mkdir /etc/containerd/certs.d  #三个节点都必须有
#再次进入前面的那个配置文件
[root@server01 ~]# vim /etc/containerd/config.toml
~~~

162行引号里面添加路径/etc/containerd/certs.d

![image-20240725160937832](https://gitee.com/xiaojinliaqi/img/raw/master/202407251609855.png)

~~~shell
#镜像加速器
[root@server01 ~]# cd /etc/containerd/certs.d/
[root@server01 certs.d]# ls
[root@server01 certs.d]# mkdir docker.io
[root@server01 certs.d]# cd docker.io/
[root@server01 docker.io]# vim hosts.toml
添加
server = "https://docker.io"

[host."https://docker.1panel.live"]
  capabilities = ["pull","resolve"]
  skip_verify = true
[host."https://docker.m.daocloud.io"]
  capabilities = ["pull","resolve"]
  skip_verify = true
[host."https://swrngwvz.mirror.aliyuncs.com"]
  capabilities = ["pull","resolve"]
  skip_verify = true
##镜像加速器 https://swrngwvz.mirror.aliyuncs.com
#02 03节点再次创建
[root@server02 ~]# mkdir /etc/containerd/certs.d/docker.io
[root@server03 ~]# mkdir /etc/containerd/certs.d/docker.io
#在01主节点上查看目录结构
[root@server01 docker.io]# cd ..
[root@server01 certs.d]# tree ./
./
└── docker.io
    └── hosts.toml
#scp拷贝镜像加速
[root@server01 docker.io]# scp hosts.toml server02:/etc/containerd/certs.d/docker.io
[root@server01 docker.io]# scp hosts.toml server03:/etc/containerd/certs.d/docker.io
~~~

![image-20240725161143408](https://gitee.com/xiaojinliaqi/img/raw/master/202407251611455.png)

~~~shell
#验证镜像仓库是否能用
[root@server01 ~]# systemctl daemon-reload
[root@server01 ~]# systemctl restart containerd.service
[root@server01 ~]# systemctl status containerd.service
~~~

![image-20240725161305098](https://gitee.com/xiaojinliaqi/img/raw/master/202407251613153.png)

~~~shell
#主配置文件scp到02，03里，保证另外两台正常启动
[root@server01 ~]# scp /etc/containerd/config.toml server02:/etc/containerd/config.toml
[root@server01 ~]# scp /etc/containerd/config.toml server03:/etc/containerd/config.toml
#验证另外两台
[root@server02 ~]# cat /etc/containerd/config.toml | grep aliyun
[root@server03 ~]# cat /etc/containerd/config.toml | grep aliyun
~~~

![image-20240725161521531](https://gitee.com/xiaojinliaqi/img/raw/master/202407251615554.png)

![image-20240725161528635](https://gitee.com/xiaojinliaqi/img/raw/master/202407251615655.png)

~~~shell
#启动节点（01，02，03都需要）
[root@server02 ~]# systemctl daemon-reload
[root@server02 ~]# systemctl restart containerd.service
[root@server02 ~]# systemctl enable containerd.service
[root@server02 ~]# systemctl status containerd.service
~~~

拉包（server01，server02，server03都需要）

![image-20240725162406155](https://gitee.com/xiaojinliaqi/img/raw/master/202407251624191.png)

![image-20240725162421016](https://gitee.com/xiaojinliaqi/img/raw/master/202407251624052.png)

~~~shell
[root@server01 ~]# tar -zxf nerdctl-1.7.6-linux-amd64.tar.gz 
[root@server01 ~]# mv nerdctl /usr/local/bin/
[root@server01 ~]# chmod +x /usr/local/bin/nerdctl 
[root@server01 ~]# rm -rf containerd-rootless.sh containerd-rootless-setuptool.sh nerdctl-1.7.6-linux-amd64.tar.gz 
#查询版本
[root@server01 ~]# nerdctl -v
#安装tab补齐
[root@server01 ~]# source <(nerdctl completion bash)
#永久生效
[root@server01 ~]# vim .bashrc
添加到最下面source <(nerdctl completion bash)
~~~

 ![image-20240725162600579](https://gitee.com/xiaojinliaqi/img/raw/master/202407251626599.png)

~~~shell
#下载镜像
[root@server01 ~]# nerdctl pull busybox:1.36
~~~

![image-20240725162708446](https://gitee.com/xiaojinliaqi/img/raw/master/202407251627489.png)

~~~shell
#查询三台节点的uuid(都不一样)
[root@server01 ~]# cat /sys/class/dmi/id/product_uuid 
[root@server02 ~]# cat /sys/class/dmi/id/product_uuid 
[root@server03 ~]# cat /sys/class/dmi/id/product_uuid 
~~~

![image-20240725162909315](https://gitee.com/xiaojinliaqi/img/raw/master/202407251629359.png)

~~~shell
#禁用swap分区，fstab里面的swap也关掉（三节点都需要）
[root@server01 ~]# vim /etc/sysctl.d/k8s.conf
最后添加：vm.swappiness = 0
~~~

![image-20240725163037882](https://gitee.com/xiaojinliaqi/img/raw/master/202407251630907.png)

~~~shell
[root@server01 ~]# vim /etc/fstab 
~~~

![image-20240725163108579](https://gitee.com/xiaojinliaqi/img/raw/master/202407251631610.png)

~~~shell
[root@server01 ~]# sudo swapoff -a
[root@server01 ~]# free -m
~~~

![image-20240725163226070](https://gitee.com/xiaojinliaqi/img/raw/master/202407251632092.png)

 ~~~shell
 #准备工作完成，开始装Kubernetrs
 网址：https://developer.aliyun.com/mirror/kubernetes?spm=a2c6h.13651102.0.0.539c1b11fvFVTU
 添加仓库：
 cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
 [kubernetes]
 name=Kubernetes
 baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/rpm/
 enabled=1
 gpgcheck=1
 gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/rpm/repodata/repomd.xml.key
 EOF
 [root@server01 ~]# vim /etc/yum.repos.d/kubernetes.repo
 ~~~

![image-20240725163531447](https://gitee.com/xiaojinliaqi/img/raw/master/202407251635482.png)

~~~shell
修改好的仓库scp到另外两个节点
[root@server01 ~]# scp /etc/yum.repos.d/kubernetes.repo server02:/etc/yum.repos.d/kubernetes.repo
[root@server01 ~]# scp /etc/yum.repos.d/kubernetes.repo server03:/etc/yum.repos.d/kubernetes.repo
~~~

![image-20240725165157109](https://gitee.com/xiaojinliaqi/img/raw/master/202407251652201.png)

~~~shell
[root@server01 ~]# dnf makecache
#查询版本
[root@server01 ~]# dnf list --showduplicates kubelet
[root@server01 ~]# dnf install -y kubelet-1.30.1 kubeadm-1.30.1 kubectl-1.30.1
##软件解释
Kubelet ：在集群中每个节点都启动
Kubeadm：初始化集群
Kubectl ：管理集群的客户端命令行工具
#安装tab补齐（三台需要）
[root@server01 ~]# vim .bashrc
最后添加：
source <(kubeadm completion bash)
source <(kubectl completion bash)
source <(crictl completion bash)
[root@server01 ~]# source .bashrc
#k8s操作容器的客户端
[root@server01 ~]# crictl images
~~~

![image-20240725165300061](https://gitee.com/xiaojinliaqi/img/raw/master/202407251653090.png)

~~~shell
[root@server01 ~]# crictl config runtime-endpoint 
添加：unix:///run/containerd/containerd.sock
[root@server01 ~]# vim /etc/crictl.yaml 
~~~

![image-20240725165420009](https://gitee.com/xiaojinliaqi/img/raw/master/202407251654047.png)

~~~shell
复制到02，03里面
[root@server01 ~]# scp /etc/crictl.yaml server02:/etc/crictl.yaml
[root@server01 ~]# scp /etc/crictl.yaml server03:/etc/crictl.yaml
#同步时间
[root@server01 ~]# dnf install chrony -yq
[root@server01 ~]# vim /etc/chrony.conf
~~~

![image-20240725165451385](https://gitee.com/xiaojinliaqi/img/raw/master/202407251654415.png)

~~~shell
[root@server01 ~]# scp /etc/chrony.conf server02:/etc/chrony.conf
[root@server01 ~]# scp /etc/chrony.conf server03:/etc/chrony.conf
[root@server01 ~]# systemctl daemon-reload
[root@server01 ~]# systemctl restart chronyd.service 
[root@server01 ~]# chronyc sources -n
~~~

![image-20240725165516307](https://gitee.com/xiaojinliaqi/img/raw/master/202407251655353.png)

~~~shell
#打印配置文件到init.yaml （只在主节点配置）
[root@server01 ~]# kubeadm config print init-defaults > init.yaml
[root@server01 ~]# vim init.yaml
修改此下
#advertiseAddress: 10.15.200.11
#name: server01
#imageRepository: registry.aliyuncs.com/google_containers
#kubernetesVersion: 1.30.1
~~~

 ![image-20240725165558769](https://gitee.com/xiaojinliaqi/img/raw/master/202407251655802.png)

~~~shell
#三台节点先enable
[root@server01 ~]# systemctl enable kubelet.service 
[root@server02 ~]# systemctl enable kubelet.service 
[root@server03 ~]# systemctl enable kubelet.service 
#进行匹配
[root@server01 ~]# kubeadm init --config=init.yaml
root@server01 ~]# mkdir -p $HOME/.kube
[root@server01 ~]# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
[root@server01 ~]# sudo chown $(id -u):$(id -g) $HOME/.kube/config
[root@server01 ~]# export KUBECONFIG=/etc/kubernetes/admin.conf
[root@server01 ~]# curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml -O
~~~

如果报错的话

![image-20240725165750220](https://gitee.com/xiaojinliaqi/img/raw/master/202407251657253.png)

~~~shell
解决方法
[root@server01 ~]# vim /etc/NetworkManager/system-connections/ens160.nmconnection
~~~

![image-20240725165828668](https://gitee.com/xiaojinliaqi/img/raw/master/202407251658703.png)

~~~shell
[root@server01 ~]# systemctl restart NetworkManager
[root@server01 ~]# curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml -O
~~~

![image-20240725165856177](https://gitee.com/xiaojinliaqi/img/raw/master/202407251658206.png)

~~~shell
[root@server01 ~]# cat init.yaml | grep 96
  serviceSubnet: 10.96.0.0/12
[root@server01 ~]# vim calico.yaml
输入/192回车就可以找到，然后修改
~~~

![image-20240725165915423](https://gitee.com/xiaojinliaqi/img/raw/master/202407251659447.png)

~~~shell
kubeadm join 10.15.200.11:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:f4b49725f4bd5617af108bf0e46a9e5747516b8c0b902a02c64b76dfba3ebcc1
[root@server02 ~]# kubeadm join 10.15.200.11:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:f4b49725f4bd5617af108bf0e46a9e5747516b8c0b902a02c64b76dfba3ebcc1
[root@server03 ~]# kubeadm join 10.15.200.11:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:f4b49725f4bd5617af108bf0e46a9e5747516b8c0b902a02c64b76dfba3ebcc1
~~~

~~~shell
#在主节点上确认控制面板是否加入节点
[root@server01 ~]# kubectl get nodes
[root@server01 ~]# kubectl get pod --namespace kube-system
~~~

![image-20240725170042255](C:/Users/%E6%9D%8E%E7%90%A6/AppData/Roaming/Typora/typora-user-images/image-20240725170042255.png)

![image-20240725170117528](https://gitee.com/xiaojinliaqi/img/raw/master/202407251701567.png)

~~~shell
#处理日志文件
[root@server01 ~]# vim /etc/rsyslog.d/01-blocklist.conf
添加：
if $msg contains "run-containerd-runc" and $msg contains "mount: Deactivated successfully." then {
        stop
}
[root@server01 ~]# systemctl restart rsyslog.service 
[root@server01 ~]# scp /etc/rsyslog.d/01-blocklist.conf server02:/etc/rsyslog.d/01-blocklist.conf
[root@server01 ~]# scp /etc/rsyslog.d/01-blocklist.conf server03:/etc/rsyslog.d/01-blocklist.conf
[root@server02 ~]# systemctl restart rsyslog.service
[root@server03 ~]# systemctl restart rsyslog.service
~~~

