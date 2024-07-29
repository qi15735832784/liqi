sudo cp /etc/selinux/config{,.bk}
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl disable firewalld
mkdir -p /var/www/html/rocky9
sudo cp /etc/fstab{,.bk}
echo "/dev/sr0  /var/www/html/rocky9 iso9660  defaults 0 0" >> /etc/fstab
mount -a
rm -fr /etc/yum.repos.d/*.repo
cat>/etc/yum.repos.d/rocky9.repo<<EOF
[AppStream]
name=AppStream
baseurl=file:///var/www/html/rocky9/AppStream
gpgcheck=0
enabled=1

[BaseOS]
name=BaseOS
baseurl=file:///var/www/html/rocky9/BaseOS
gpgcheck=0
enabled=1
EOF
yum makecache
yum install vim httpd -y -q
rm -fr /etc/httpd/conf.d/welcome.conf
systemctl enable httpd

