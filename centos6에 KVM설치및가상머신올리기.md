

��ó : http://www.cyberciti.biz/faq/kvm-virtualization-in-redhat-centos-scientific-linux-6/

### �غ�
vi /etc/selinux/config
SELINUX=disabled
reboot

###  KVM RPMs/packages ��ġ 
yum groupinstall -y "Virtualisation Tools" "Virtualization Platform"
yum install -y python-virtinst wget 

###  libvirtd service ���
chkconfig libvirtd on
service libvirtd start

### network bridge ����
vi /etc/sysconfig/network  # �Ʒ��� ���� ���� 
NETWORKING=yes
HOSTNAME=myhostname
## I am routing internet traffic via br1 ##
GATEWAYDEV=br1


vi /etc/sysconfig/network-scripts/ifcfg-eth1   # WAN/Internet �� interface
DEVICE=eth1
ONBOOT=yes
HWADDR=00:30:48:C6:0A:D9
BRIDGE=br1    # <-- �̰��� �߿���.

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

# network bridge Ȯ��
brctl show
ip addr show br1
ip route
ping cyberciti.biz