CAP
=====

docker-centos-hadoop-cluster


- [Docker ������ CentOS�� ��ġ] (https://docs.docker.com/engine/installation/centos/)
- [Docker ��������� ����](http://longbe00.blogspot.kr/2015/03/docker_55.html)
- [Hadoop Cluster based on Docker Ubuntu ](https://github.com/kiwenlau/hadoop-cluster-docker)
- [docker-centos-serf](https://github.com/FayeHuang/docker-centos-serf)
- [docker�� ���� ������ �Ҵ��ϱ�](http://jhouse0317.tistory.com/entry/%EB%8F%84%EC%BB%A4%EC%97%90-%EA%B3%A0%EC%A0%95-%EC%95%84%EC%9D%B4%ED%94%BC-%ED%95%A0%EB%8B%B9%ED%95%98%EA%B8%B0)
- [Docker container networks - ��Ƽȣ��Ʈ���� �����ϴ� �ϳ��� ��Ʈ��ũ �����](https://docs.docker.com/engine/userguide/networking/dockernetworks/#an-overlay-network)
- [Get started with multi-host networking] (https://docs.docker.com/engine/userguide/networking/get-started-overlay/)
- [Advanced Docker Networking with Pipework](https://opsbot.com/advanced-docker-networking-pipework/)
- [Multi-Host Docker Networking is now ready for production](https://blog.docker.com/2015/11/docker-multi-host-networking-ga/)
- CentOS7���� ��Ƽ ȣ���� ��Ʈ��ũ ���� 

```
#######################################
# CentOS7���� docker ��ġ
#######################################
https://docs.docker.com/engine/installation/centos/

$ sudo yum update
$ sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

$ sudo yum install docker-engine
$ sudo service docker start
$ sudo chkconfig docker on
$ sudo docker info

#######################################
# Docker �۾� ���丮�� ����
#######################################
https://docs.docker.com/engine/articles/systemd/

$ mkdir /home/docker

$ cp -R  /var/lib/docker/* /home/docker 

# service file ��ġ Ȯ��
$ sudo systemctl status docker | grep Loaded

#service file�� �Ʒ� ���� �߰�
EnvironmentFile=-/etc/sysconfig/docker
$OPTIONS  �߰�

$ sudo vi /etc/sysconfig/docker
OPTIONS="-g /home/docker"

$ sudo reboot



#######################################
## CentOS7���� docker�� multi-host networking ����
#######################################

https://docs.docker.com/engine/userguide/networking/get-started-overlay/

######################################
# ���� �۾�
# 1. CentOS7���� kernel�� 3.18�� ���׷��̵�

wget http://mirrors.neterra.net/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-3.18.6-1.el7.elrepo.x86_64.rpm
wget http://mirrors.neterra.net/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-devel-3.18.6-1.el7.elrepo.x86_64.rpm

rpm -Uvh kernel-ml-3.18.6-1.el7.elrepo.x86_64.rpm
rpm -Uvh kernel-ml-devel-3.18.6-1.el7.elrepo.x86_64.rpm

vi /boot/grub2/grubenv
saved_entry=CentOS Linux (3.18.6-1.el7.elrepo.x86_64) 7 (Core)  �� ������.

reboot 

# Ŀ�ι��� Ȯ��
uname -r 
3.18.6-1.el7.elrepo.x86_64

######################################
# 2. docker-machine ��ġ
https://docs.docker.com/machine/install-machine/

curl -L https://github.com/docker/machine/releases/download/v0.5.3/docker-machine_linux-amd64 >/usr/local/bin/docker-machine && \
    chmod +x /usr/local/bin/docker-machine

docker-machine version

######################################
# 3.  VirtualBox5 ��ġ
http://www.if-not-true-then-false.com/2010/install-virtualbox-with-yum-on-fedora-centos-red-hat-rhel/

cd /etc/yum.repos.d/
wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
yum update
reboot

rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install VirtualBox-5.0

export KERN_DIR=/usr/src/kernels/3.18.6-1.el7.elrepo.x86_64/
/usr/lib/virtualbox/vboxdrv.sh setup
```

