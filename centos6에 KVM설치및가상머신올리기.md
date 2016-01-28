
# CentOS6���� KVM ��ġ �� ����ӽ� �ø���
- ��ó : http://www.cyberciti.biz/faq/kvm-virtualization-in-redhat-centos-scientific-linux-6/

## 1. HOST ���� �غ�

###  CentOS ��ġ
- centos6.7 �ּҼ�ġ������ ��ġ��.
- ��ġ���Ŀ� �Ʒ��� ���� selinux �� disabled ��.

```
vi /etc/selinux/config
SELINUX=disabled
reboot
```

###  KVM RPMs/packages ��ġ 
```
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum groupinstall -y "Virtualisation Tools" "Virtualization Platform" "development tools"
yum install -y libguestfs-tools python-virtinst kvm  python-pip wget libxml2 libxml2-devel libxslt-devel python-devel
pip install lxml 
``` 

###  libvirtd service ���
```
chkconfig libvirtd on
service libvirtd start
```

### network bridge ����
```
vi /etc/sysconfig/network  # �Ʒ��� ���� ���� 
NETWORKING=yes
HOSTNAME=myhostname
## I am routing internet traffic via br1 ##
GATEWAYDEV=br1
```

```
vi /etc/sysconfig/network-scripts/ifcfg-eth1   # WAN/Internet �� interface
DEVICE=eth1
ONBOOT=yes
HWADDR=00:30:48:C6:0A:D9
BRIDGE=br1    # <-- �̰��� �߿���.
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

- network bridge Ȯ��
```
brctl show
ip addr show br1
ip route
ping cyberciti.biz
```

- centos6.7_default ����Ʈ �̹��� �����
- �͹̳ο��� ��ɾ�θ����� �� ��������� �ʾƼ� KVM UI ���α׷����� ����.

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

- VM �����ϱ� 
```
VM_NAME=node01
virsh shutdown $VM_NAME
virsh destroy $VM_NAME
virsh undefine $VM_NAME
rm -f /home/kvm/images/${VM_NAME}.img
```

## 2. KVM �Խ�Ʈ( VM ) ���� ����
- http://www.greenhills.co.uk/2013/03/24/cloning-vms-with-kvm.html


- KVM���� �ּҼ�ġ �������� centos6.7 VM�� ���� �̸� �̹����� ����� ����
   - �͹̳ο��� ��ɾ�θ����� �� ��������� �ʾƼ� KVM UI ���α׷����� ����.
   - ��Ʈ��ũ�� �ڵ������ ������. 
```
yum install -y bind-utils
yum install -y vim
yum install -y ntsysv
yum install -y system-config-firewall-tui
yum install -y system-config-network
``` 

- KVM �� ���丮 �����
```
mkdir -p /home/kvm/images
cd /home/kvm/
```

- IP �� MAC �ּ� �����
- vi generate-ips.py  ���Ͽ� �Ʒ� ���� �ֱ�
```
#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# generate vm network range

import virtinst.util
for num in range(110, 130+1):
    print("vm{0}\t192.168.0.{0}\t{1}".format(num, virtinst.util.randomMAC()))
```

- python generate-ips.py  > ips.txt

- vi generate-openwrt.py ���Ͽ� �Ʒ� ���� �ֱ� 
```
#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# generate openwrt /etc/config/dhcp config

import sys
for line in sys.stdin:
    (ip, name, mac) = line.split()
    print("config domain\n\toption name '{0}'\n\toption ip '{1}'\n\n".format(name, ip))
    print("config host\n\toption mac '{0}'\n\toption name '{1}'\n\toption ip '{2}'\n\n".format(mac, name, ip))
```

- python generate-openwrt.py < ips.txt


- �̸� ����� ���� CentOS �̹�����  : /home/kvm/images/centos6.7_default 
- VM�� �������� �����ϴ� ��ũ��Ʈ
- vi clone-vm.sh �Ʒ� ���� �߰�
```
VM=$1
VM_IMAGE_DIR=/home/kvm/images
WORK_DIR=/home/kvm/working/${VM}

cp ${VM_IMAGE_DIR}/centos6.7_default  ${VM_IMAGE_DIR}/vm-${VM}

rm -rf ${WORK_DIR}/tmp && mkdir -p ${WORK_DIR}/tmp
virsh dumpxml centos6.7_default > ${WORK_DIR}/tmp/centos6.7_default.xml
mac=`egrep "^$VM"'\s' ips.txt | awk '{print $3}'`; echo $mac   # ��ũ��Ʈ ���۽� �Է� ���� �Ǵ� DB �Ǵ� random�ϰ� mac ���� ������ ������ ���� �ʿ���. 
python ./modify-domain.py \
    --name $VM \
    --new-uuid \
    --device-path=${VM_IMAGE_DIR}/vm-${VM} \
    --mac-address $mac \
    < ${WORK_DIR}/tmp/centos6.7_default.xml > ${WORK_DIR}/tmp/$VM.xml
virsh define ${WORK_DIR}/tmp/$VM.xml
virsh dumpxml $VM # Ȯ�ο�  ��� ��.


mkdir -p ${WORK_DIR}/templates
cat > ${WORK_DIR}/templates/network-interfaces <<NET
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
IPADDR=IP_ADDRESS_GOES_HERE
HWADDR=MAC_GOES_HERE
GATEWAY=192.168.0.1
NETMASK=255.255.255.0
DNS1=8.8.8.8
DNS2=8.8.4.4
NET


cat > ${WORK_DIR}/templates/hosts <<HOSTS
127.0.0.1   localhost
IP_ADDRESS_GOES_HERE   VM_NAME_GOES_HERE
HOSTS


cat > ${WORK_DIR}/templates/configure.sh <<SCRIPT
#!/bin/bash
# Run in the host, with the cwd being the root of the guest

set -x
cp ${WORK_DIR}/tmp/network-interfaces.VM_NAME_GOES_HERE etc/sysconfig/network-scripts/ifcfg-eth0
cp ${WORK_DIR}/tmp/hosts.VM_NAME_GOES_HERE etc/hosts

# re-generate the keys. Letting virt-sysprep remove the keys
# is insufficient, and they don't get automatically regenerated
# on boot by Ubuntu. A dpkg-reconfigure fails for some reason,
# and doing a boot-time script is overkill, so just do it now explicitly.
# �Ʒ� �ڵ�� Centos�� �°� ���� �ʿ���.
rm etc/ssh/ssh_host_rsa_key etc/ssh/ssh_host_rsa_key.pub
rm etc/ssh/ssh_host_dsa_key etc/ssh/ssh_host_dsa_key.pub
rm etc/ssh/ssh_host_ecdsa_key etc/ssh/ssh_host_ecdsa_key.pub
ssh-keygen -h -N '' -t rsa -f etc/ssh/ssh_host_rsa_key
ssh-keygen -h -N '' -t dsa -f etc/ssh/ssh_host_dsa_key
ssh-keygen -h -N '' -t ecdsa -f etc/ssh/ssh_host_ecdsa_key
SCRIPT


ip=`egrep "^$VM\s" ips.txt | awk '{print $2}'`; echo $ip   # DB �Ǵ� ��ũ��Ʈ�� ���۽� �Է� ������ �޵���  ���� �ʿ���. 
sed -e "s/IP_ADDRESS_GOES_HERE/$ip/g" -e "s/VM_NAME_GOES_HERE/$VM/g" < ${WORK_DIR}/templates/hosts > ${WORK_DIR}/tmp/hosts.$VM
sed -e "s/IP_ADDRESS_GOES_HERE/$ip/g" -e "s/VM_NAME_GOES_HERE/$VM/g" -e "s/MAC_GOES_HERE/$mac/g"  < ${WORK_DIR}/templates/network-interfaces > ${WORK_DIR}/tmp/network-interfaces.$VM

sed -e "s/IP_ADDRESS_GOES_HERE/$ip/g" -e "s/VM_NAME_GOES_HERE/$VM/g" < ${WORK_DIR}/templates/configure.sh > ${WORK_DIR}/tmp/configure.sh.$VM
chmod a+x ${WORK_DIR}/tmp/configure.sh.$VM
virt-sysprep -d $VM \
  --verbose \
  --enable udev-persistent-net,bash-history,hostname,logfiles,utmp,script \
  --hostname $VM \
  --script ${WORK_DIR}/tmp/configure.sh.$VM

virsh start $VM

```

- VM ����

```
VM_IMAGE_DIR=/home/kvm/images
VM=vm111

virsh shutdown $VM
virsh destroy $VM
virsh undefine $VM
rm -f ${VM_IMAGE_DIR}/vm-${VM}
```