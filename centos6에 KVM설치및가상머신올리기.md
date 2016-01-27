
# CentOS6에서 KVM 설치 및 가상머신 올리기
- 출처 : http://www.cyberciti.biz/faq/kvm-virtualization-in-redhat-centos-scientific-linux-6/

### 준비
```
vi /etc/selinux/config
SELINUX=disabled
reboot
```

###  KVM RPMs/packages 설치 
```
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum groupinstall -y "Virtualisation Tools" "Virtualization Platform" "development tools"
yum install -y libguestfs-tools python-virtinst kvm  python-pip wget libxml2 libxml2-devel libxslt-devel python-devel
pip install lxml 
``` 

###  libvirtd service 등록
```
chkconfig libvirtd on
service libvirtd start
```

### network bridge 설정
```
vi /etc/sysconfig/network  # 아래와 같이 수정 
NETWORKING=yes
HOSTNAME=myhostname
## I am routing internet traffic via br1 ##
GATEWAYDEV=br1
```

```
vi /etc/sysconfig/network-scripts/ifcfg-eth1   # WAN/Internet 용 interface
DEVICE=eth1
ONBOOT=yes
HWADDR=00:30:48:C6:0A:D9
BRIDGE=br1    # <-- 이것이 중요함.
```

```
vi /etc/sysconfig/network-scripts/ifcfg-br1
DEVICE=br1
TYPE=Bridge
BOOTPROTO=static
ONBOOT=yes
## setup INTERNET ips as per your needs ##
IPADDR=192.168.0.8
NETMASK=255.255.255.255
GATEWAY=192.168.0.1
DELAY=0
```

```
service network restart
```

- network bridge 확인
```
brctl show
ip addr show br1
ip route
ping cyberciti.biz
```
centos6.7_default

- https://www.youtube.com/watch?v=nVvHCb-ixF4 

virt-install --name=node01 \
   --disk path=/home/kvm/images/node01.img,size=10 \
   --ram=1024 \
   --vcpus=1 \
   --os-type=linux \
   --os-variant=rhel6 \
   --network bridge:br1  \
   --nographics  \
   --cdrom=/home/kvm/CentOS-6.7-x86_64-minimal.iso   

   --description "CentOS6.7 minimal VM" \    
   --cpu host \

- VM 삭제하기 
```
VM_NAME=node01
virsh shutdown $VM_NAME
virsh destroy $VM_NAME
virsh undefine $VM_NAME
rm -f /home/kvm/images/${VM_NAME}.img
```

### VM 동적 생성
- http://www.greenhills.co.uk/2013/03/24/cloning-vms-with-kvm.html


mkdir -p tmp
virsh dumpxml centos6.7_default > tmp/centos6.7_default.xml
mac=`egrep "^$VM"'\s' ips.txt | awk '{print $3}'`; echo $mac
python ./modify-domain.py \
    --name $VM \
    --new-uuid \
    --device-path=/home/kvm/images/vms-$VM \
    --mac-address $mac \
    < tmp/centos6.7_default.xml > tmp/$VM.xml
virsh define tmp/$VM.xml
virsh dumpxml $VM




yum install -y bind-utils
yum install -y vim
yum install -y ntsysv
yum install -y system-config-firewall-tui
yum install -y system-config-network
