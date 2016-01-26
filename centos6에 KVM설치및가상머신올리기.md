

출처 : http://www.cyberciti.biz/faq/kvm-virtualization-in-redhat-centos-scientific-linux-6/

### 준비
vi /etc/selinux/config
SELINUX=disabled
reboot

###  KVM RPMs/packages 설치 
yum groupinstall -y "Virtualisation Tools" "Virtualization Platform"
yum install -y python-virtinst wget 

###  libvirtd service 등록
chkconfig libvirtd on
service libvirtd start

### network bridge 설정
vi /etc/sysconfig/network  # 아래와 같이 수정 
NETWORKING=yes
HOSTNAME=myhostname
## I am routing internet traffic via br1 ##
GATEWAYDEV=br1


vi /etc/sysconfig/network-scripts/ifcfg-eth1   # WAN/Internet 용 interface
DEVICE=eth1
ONBOOT=yes
HWADDR=00:30:48:C6:0A:D9
BRIDGE=br1    # <-- 이것이 중요함.

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

service network restart

# network bridge 확인
brctl show
ip addr show br1
ip route
ping cyberciti.biz