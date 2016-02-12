
# CentOS6에 Kerberos 보안설정

## 준비
- root 권한으로
- pssh 설치
```
cd /usr/local/src
wget http://parallel-ssh.googlecode.com/files/pssh-2.1.1.tar.gz
tar xvf pssh-2.1.1.tar.gz
cd pssh-2.1.1
wget 'http://peak.telecommunity.com/dist/ez_setup.py'
python ez_setup.py
python setup.py install


cat > ~/hosts.txt <<HOSTS
vm111
vm112
vm211
vm212
HOSTS

cat > ~/all_hosts.txt <<HOSTS
locahost
vm111
vm112
vm211
vm212
HOSTS

rm -rf ~/.ssh/
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub localhost
ssh-copy-id -i ~/.ssh/id_rsa.pub vm111 ~ vm211

pscp -h ~/hosts.txt ~/.ssh/authorized_keys  ~/.ssh/ 
pscp -h ~/hosts.txt ~/.ssh/id_rsa  ~/.ssh/
pscp -h ~/hosts.txt ~/.ssh/id_rsa.pub  ~/.ssh/
pscp -h ~/hosts.txt ~/.ssh/known_hosts  ~/.ssh/

pssh -h ~/hosts.txt service iptables stop
pssh -h ~/hosts.txt chkconfig iptables off
```

## Kerberos 설정
- 출처 : http://bloodguy.tistory.com/954
- Kerberos는 fault tolerance를 위해 replication을 제공함.
- master-slave(s)로 구성되며, 평소에는 master에서 다 처리하고 주기적으로 master의 db를 slave(s)에 sync하는 방식으로 유지되다가, master가 죽으면 slave가 처리하는 방식.
    - 1. 서버는 master(vm111), slave(vm112)로 구성.
    - 2. hostname은 kocap.com이며 realm은 KOCAP.COM
    - 3. centos 기준

- 설치용 패키지 받기
```
mkdir -p /home/kvm/kocap/
cd /home/kvm/kocap/
svn co  svn://xxx.xxx.xxx.xxx/NGT/BigData/Sources/HadoopMonitoring/installer2.4  --username  ID  --password 비번
cd installer2.4 
```

- root 권한으로
```
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/portreserve-0.0.4-9.el6.x86_64.rpm  ~/ 
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/words-3.0-17.el6.noarch.rpm  ~/
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/krb5-server-1.10.3-42.el6.x86_64.rpm  ~/
#pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/krb5-libs-1.10.3-42.el6.x86_64.rpm  ~/
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/krb5-workstation-1.10.3-42.el6.x86_64.rpm  ~/

pssh -h ~/hosts.txt  rpm -Uvh portreserve-0.0.4-9.el6.x86_64.rpm
pssh -h ~/hosts.txt  rpm -Uvh words-3.0-17.el6.noarch.rpm
pssh -h ~/hosts.txt  rpm -Uvh krb5-server-1.10.3-42.el6.x86_64.rpm
#pssh -h ~/hosts.txt  rpm -Uvh krb5-libs-1.10.3-42.el6.x86_64.rpm
pssh -h ~/hosts.txt  rpm -Uvh krb5-workstation-1.10.3-42.el6.x86_64.rpm

```


- vm111에 접속해서 
- vi /etc/krb5.conf
```
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = KOCAP.COM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 KOCAP.COM = {
  kdc = vm111:88
  kdc = vm112:88
  admin_server = vm111:749
  default_domain = kocap.com
 }

[domain_realm]
 .kocap.com = KOCAP.COM
 kocap.com = KOCAP.COM

```

- vi /var/kerberos/krb5kdc/kdc.conf
```
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 KOCAP.COM = {
  #master_key_type = aes256-cts
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
 }
```

- vi /var/kerberos/krb5kdc/kadm5.acl
```
*/admin@KOCAP.COM       *
```


- Database 생성 : 시간이 많이 걸림, 당황하지 말고 기다리자.
```
kdb5_util create -s
```

- kadmin 시작
```
service kadmin start
```

- 최초 관리자 생성
```
kadmin.local -q "addprinc admin/admin"
service krb5kdc start
```

- 테스트
```
kadmin -p admin/admin
// principal 추가
kadmin: addprinc kocap/kocap.com@KOCAP.COM

// 비번 입력
kocap

// 추가된 principal 확인
kadmin: listprincs

// 종료
quit


// 인증 테스트
kinit kocap/kocap.com
// 비번 입력
kocap


// 티켓 확인
klist

// 티켓 삭제
kdestroy
klist

```

## Kerberos Clients 설치 및 설정
```
##  client를 모든 클러스터에 설치
rpm -Uvh krb5-workstation-1.10.3-42.el6.x86_64.rpm

## krb5.conf을 모든 클러스터에 설치
[root@vm111]scp /etc/krb5.conf                          root@vm211:/etc
[root@vm111]scp /etc/krb5.conf                          root@vm212:/etc
```
 

## Kerberos 복제( 이중화 )
- host principal 생성
```
[root@vm111]# kadmin  -p admin/admin
kadmin: addprinc -randkey host/vm111
kadmin: addprinc -randkey host/vm112

kadmin: ktadd host/vm111
kadmin: ktadd host/vm112
kadmin: quit
```

- keytab 복사 master -> slave
```
[root@vm111]# scp /etc/krb5.keytab root@vm112:/etc
```

- 각종 설정파일 복사 master -> slave
```
[root@vm111]# 
scp /etc/krb5.conf                          root@vm112:/etc
scp /var/kerberos/krb5kdc/kdc.conf          root@vm112:/var/kerberos/krb5kdc
scp /var/kerberos/krb5kdc/kadm5.acl         root@vm112:/var/kerberos/krb5kdc
scp /var/kerberos/krb5kdc/.k5.KOCAP.COM     root@vm112:/var/kerberos/krb5kdc
```

- slave vm112에서 /var/kerberos/krb5kdc/kpropd.acl 파일을 만들고 아래 내용 입력 후 저장
```
host/vm111@KOCAP.COM
host/vm112@KOCAP.COM
```

- slave에서 kpropd 시작
```
[root@vm112]# service kprop start
```

- db dump
```
[root@vm111]# kdb5_util dump /var/kerberos/krb5kdc/slave_datatrans
## slave_datatrans, slave_datatrans.dump_ok 파일 존재여부 확인
ls -l /var/kerberos/krb5kdc/
```

- master -> slave db propagate
```
[root@vm111]# kprop -f /var/kerberos/krb5kdc/slave_datatrans vm112
Database propagation to vm112: SUCCEEDED
```

- slave에서 propagation 결과확인
```
## /var/kerberos/krb5kdc 디렉토리에 principal 관련 파일들과 from_master라는 파일이 있어야 함.
[root@vm112]# ls -l /var/kerberos/krb5kdc
```

- slave의 krb5kdc 시작
```
[root@vm112]# service krb5kdc start
```

## failover 테스트
- master kdc stop
```
[root@vm111]# service krb5kdc stop
```


- kinit 테스트
```
[root@vm111]# kinit kocap/kocap.com
Password for kocap/kocap.com@KCAP.COM:
// 비번 입력
kocap
```

- slave인 vm112의 krb5kdc를 통해 성공함.
- vm112의 /var/log/krb5kdc.log 보면 아래와 같은 인증성공 로그를 확인 가능.
```
vi /var/log/krb5kdc.log
...
Apr 17 15:11:34 kdc2.bloodguy.com krb5kdc[6458](info): AS_REQ (12 etypes {18 17 16 23 1 3 2 11 10 15 12 13}) 111.111.111.111: ISSUE: authtime 1429251094, etypes {rep=18 tkt=18 ses=18}, admin/bloodguy.com@BLOODGUY.COM for krbtgt/BLOODGUY.COM@BLOODGUY.COM
```


- 주기적인 db propagation을 위해 스크립트를 하나 만듬.
``` 
vi /var/kerberos/krb5kdc/repl.sh
#!/bin/sh
 
kdclist="vm112.kocap.com"
/usr/kerberos/sbin/kdb5_util dump /var/kerberos/krb5kdc/slave_datatrans
for kdc in $kdclist
do
    /usr/kerberos/sbin/kprop -f /var/kerberos/krb5kdc/slave_datatrans $kdc
done


실행권한을 주고
[root@vm111]# chmod 0755 /var/kerberos/krb5kdc/repl.sh

crontab에 아래처럼 등록. 5분에 한 번씩 master-slave db sync
*/5 * * * * /var/kerberos/krb5kdc/repl.sh
```



