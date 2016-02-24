
# Hadoop2.4에 Kerberos보안설정하는방법
- 사전 작업
    - centos6에 [Kerberos보안설정.md](https://github.com/minheelee/kocap/blob/master/centos6%EC%97%90%20Kerberos%EB%B3%B4%EC%95%88%EC%84%A4%EC%A0%95.md)
    - centos6에 [hadoop2.4설치및HA구성.md](https://github.com/minheelee/kocap/blob/master/centos6%EC%97%90%20hadoop2.4%EC%84%A4%EC%B9%98%EB%B0%8FHA%EA%B5%AC%EC%84%B1.md)
    - centos6에 [Zookeeper에 Kerberos보안설정하는방법](https://github.com/minheelee/kocap/blob/master/Zookeeper%EC%97%90%20Kerberos%EB%B3%B4%EC%95%88%EC%84%A4%EC%A0%95%ED%95%98%EB%8A%94%EB%B0%A9%EB%B2%95.md)

- 출처 : http://bloodguy.tistory.com/entry/Hadoop-%EB%B3%B4%EC%95%88%EC%84%A4%EC%A0%95-security-kerberos-spnego-ssl

## Kerberos 설정

- principal 생성
- FQDN(FullyQualifiedDomainName)별로 생성하므로 서버별로 각 3개씩의 principal이 필요함.
    - hdfs/FQDN
    - yarn/FQDN
    - HTTP/FQDN
```
## principal 추가
## 전체 서버별로 principal 3개씩 생성.

## kadmin으로 접속
[root@vm111]# kadmin -p admin/admin@KOCAP.COM
## vm111
kadmin: addprinc -randkey hdfs/vm111@KOCAP.COM
kadmin: addprinc -randkey yarn/vm111@KOCAP.COM
kadmin: addprinc -randkey HTTP/vm111@KOCAP.COM
## ~~~ serverNN 까지 생성

addprinc -randkey hdfs/vm111@KOCAP.COM
addprinc -randkey yarn/vm111@KOCAP.COM
addprinc -randkey HTTP/vm111@KOCAP.COM

addprinc -randkey hdfs/vm112@KOCAP.COM
addprinc -randkey yarn/vm112@KOCAP.COM
addprinc -randkey HTTP/vm112@KOCAP.COM

addprinc -randkey hdfs/vm211@KOCAP.COM
addprinc -randkey yarn/vm211@KOCAP.COM
addprinc -randkey HTTP/vm211@KOCAP.COM

addprinc -randkey hdfs/vm212@KOCAP.COM
addprinc -randkey yarn/vm212@KOCAP.COM
addprinc -randkey HTTP/vm212@KOCAP.COM

```

- keytab 생성
    - 각 서버마다 아래와 같은 principal을 포함하는 2개의 keytab 파일이 필요함.
        - hdfs.keytab = hdfs/FQDN + HTTP/FQDN
        - yarn.keytab = yarn/FQDN + HTTP/FQDN
```
## 설치된 Kerberos가 -norandkey 옵션을 지원하지 않을 경우 아래처럼 keytab을 각 principal별로 따로 만든 후 ktutil로 합쳐야 함.
## vm111
kadmin: xst -k vm111-HTTP.keytab          HTTP/vm111@KOCAP.COM
kadmin: xst -k vm111-hdfs-unmerged.keytab hdfs/vm111@KOCAP.COM
kadmin: xst -k vm111-yarn-unmerged.keytab yarn/vm111@KOCAP.COM
## ~~~ serverNN 까지 생성

xst -k vm111-HTTP-unmerged.keytab HTTP/vm111@KOCAP.COM
xst -k vm111-hdfs-unmerged.keytab hdfs/vm111@KOCAP.COM
xst -k vm111-yarn-unmerged.keytab yarn/vm111@KOCAP.COM

xst -k vm112-HTTP-unmerged.keytab HTTP/vm112@KOCAP.COM
xst -k vm112-hdfs-unmerged.keytab hdfs/vm112@KOCAP.COM
xst -k vm112-yarn-unmerged.keytab yarn/vm112@KOCAP.COM

xst -k vm211-HTTP-unmerged.keytab HTTP/vm211@KOCAP.COM
xst -k vm211-hdfs-unmerged.keytab hdfs/vm211@KOCAP.COM
xst -k vm211-yarn-unmerged.keytab yarn/vm211@KOCAP.COM

xst -k vm212-HTTP-unmerged.keytab HTTP/vm212@KOCAP.COM
xst -k vm212-hdfs-unmerged.keytab hdfs/vm212@KOCAP.COM
xst -k vm212-yarn-unmerged.keytab yarn/vm212@KOCAP.COM

kadmin: quit

## 합치기 
[root@vm111]# ktutil
// hdfs.keytab
ktutil: rkt hdfs-unmerged.keytab
ktutil: rkt HTTP-unmerged.keytab
ktutil: wkt hdfs.keytab
ktutil: clear
// yarn.keytab
ktutil: rkt yarn-unmerged.keytab
ktutil: rkt HTTP-unmerged.keytab
ktutil: wkt yarn.keytab
ktutil: quit
## ~~~ serverNN 까지 생성
rkt vm111-hdfs-unmerged.keytab
rkt vm111-HTTP-unmerged.keytab
wkt vm111-hdfs.keytab
clear
rkt vm111-yarn-unmerged.keytab
rkt vm111-HTTP-unmerged.keytab
wkt vm111-yarn.keytab
clear

rkt vm112-hdfs-unmerged.keytab
rkt vm112-HTTP-unmerged.keytab
wkt vm112-hdfs.keytab
clear
rkt vm112-yarn-unmerged.keytab
rkt vm112-HTTP-unmerged.keytab
wkt vm112-yarn.keytab
clear

rkt vm211-hdfs-unmerged.keytab
rkt vm211-HTTP-unmerged.keytab
wkt vm211-hdfs.keytab
clear
rkt vm211-yarn-unmerged.keytab
rkt vm211-HTTP-unmerged.keytab
wkt vm211-yarn.keytab
clear

rkt vm212-hdfs-unmerged.keytab
rkt vm212-HTTP-unmerged.keytab
wkt vm212-hdfs.keytab
clear
rkt vm212-yarn-unmerged.keytab
rkt vm212-HTTP-unmerged.keytab
wkt vm212-yarn.keytab
clear

quit
```

- 필요없는 keytab 파일 삭제
```
rm -f *unmerged.keytab
```

- 퍼미션 설정
```
chown fbpuser:fbpgroup *.keytab
chmod 400 *.keytab
```

- 각각의 서버에 배포
```
cp *.keytab  /home/fbpuser/
su fbpuser
cd  
scp vm111-hdfs.keytab  vm111:/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab
scp vm111-yarn.keytab  vm111:/home/fbpuser/hadoop-2.4.1/etc/hadoop/yarn.keytab

scp vm112-hdfs.keytab  vm112:/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab
scp vm112-yarn.keytab  vm112:/home/fbpuser/hadoop-2.4.1/etc/hadoop/yarn.keytab

scp vm211-hdfs.keytab  vm211:/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab
scp vm211-yarn.keytab  vm211:/home/fbpuser/hadoop-2.4.1/etc/hadoop/yarn.keytab

scp vm212-hdfs.keytab  vm212:/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab
scp vm212-yarn.keytab  vm212:/home/fbpuser/hadoop-2.4.1/etc/hadoop/yarn.keytab

```


## Directory Permission
- HDFS (로컬 디렉토리가 아니라 HDFS 디렉토리임에 주의)
- hdfs와 yarn에 대한 사용자가 fbpuser로 동일하므로 특별히 변경이 필요없음.
- 각각 다른 경우에 아래를 참고함.
```
/* 
/    = hdfs:hadoop (775)
*/
hdfs dfs -chown hdfs:hadoop /
hdfs dfs -chmod 775 /


/* 
/tmp = hdfs:hadoop (777)
*/
hdfs dfs -chown hdfs:hadoop /tmp
hdfs dfs -chmod 777 /tmp

/* 
/user = hdfs:hadoop (755)
*/
hdfs dfs -chown hdfs:hadoop /user
hdfs dfs -chmod 755 /user

/*
yarn.nodemanager.remote-app-log-dir[/tmp/logs] = yarn:hadoop (777)
*/
hdfs dfs -chown yarn:hadoop /tmp/logs
hdfs dfs -chmod 777 /tmp/logs

hdfs dfs -chown yarn:hadoop /tmp/hadoop-yarn
hdfs dfs -chmod 777 /tmp/hadoop-yarn
```

- Local (전체 서버 대상)
```
// dfs.namenode.name.dir = hdfs:hadoop (700)
[root@vm111]# chown -R hdfs:hadoop /home/fbpuser/data/hadoop/repository/dfs/name
[root@vm111]# chmod 700 /home/fbpuser/data/hadoop/repository/dfs/name

// dfs.datanode.data.dir = hdfs:hadoop (700)
[root@vm111]# chown -R hdfs:hadoop /home/fbpuser/data/hadoop/repository/dfs/data
[root@vm111]# chmod 700 /home/fbpuser/data/hadoop/repository/dfs/data

// dfs.journalnode.edits.dir = hdfs:hadoop (700)
[root@vm111]# chown -R hdfs:hadoop /home/fbpuser/data/hadoop/repository/dfs/journalnode
[root@vm111]# chmod 700 /home/fbpuser/data/hadoop/repository/dfs/journalnode

// $HADOOP_LOG_DIR       = hdfs:hadoop (775)
[root@vm111]# chown -R hdfs:hadoop /home/fbpuser/hadoop-2.4.1/logs
[root@vm111]# chmod 775 /home/fbpuser/hadoop-2.4.1/logs

// $YARN_LOG_DIR         = yarn:hadoop (775)
// 위와 동일한 경로(/home/fbpuser/hadoop-2.4.1/logs)로 세팅했으므로 생략.

// yarn.nodemanager.local-dirs = yarn:hadoop (755)
[root@vm111]# chown -R yarn:hadoop /home/fbpuser/data/hadoop/repository/yarn/nm-local-dir
[root@vm111]# chmod 755 /home/fbpuser/data/hadoop/repository/yarn/nm-local-dir

// yarn.nodemanager.log-dirs   = yarn:hadoop (755)
// 위와 동일한 경로(/home/fbpuser/hadoop-2.4.1/logs)로 세팅했으므로 생략.
```


## container-executor 빌드
- Hadoop 소스코드와 빌드할 수 있는 환경이 세팅되어 있어야 함.
- [CentOS6에 Hadoop2.4설치 및 HA구성 참고](https://github.com/minheelee/kocap/blob/master/centos6%EC%97%90%20hadoop2.4%EC%84%A4%EC%B9%98%EB%B0%8FHA%EA%B5%AC%EC%84%B1.md)
- 소스코드가 있고 빌드환경 세팅이 완료되었다면 아래와 같은 과정을 거쳐 빌드 및 설정.
- 이 과정이 필요한지 확인하지 않았음.

```
// /home/src/hadoop-2.6.0-src 디렉토리에 소스코드 압축이 풀려있다고 가정함.

// 빌드
[root@vm111]# cd /home/src/hadoop-2.6.0-src/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-nodemanager/
[root@vm111]# mvn package -Dcontainer-executor.conf.dir=/home/hadoop/etc/hadoop -DskipTests -Pnative

// 빌드 결과물 옮기기
[root@vm111]# cp target/native/target/usr/local/bin/* /home/hadoop/bin

// 퍼미션
[root@vm111]# cd /home/hadoop/bin
[root@vm111]# chown root:hadoop container-executor 
[root@vm111]# chmod 6050 container-executor

// cfg 파일 설정
[root@vm111]# vi /home/hadoop/etc/hadoop/container-executor.cfg

yarn.nodemanager.linux-container-executor.group=hadoop
#banned.users=
min.user.id=500
#allowed.system.users=

// cfg 파일 퍼미션 설정
[root@vm111]# chown root:hadoop /home/hadoop/etc/hadoop/container-executor.cfg
[root@vm111]# chmod 0400 /home/hadoop/etc/hadoop/container-executor.cfg

// cfg 파일의 경우 전체 서버에 배포.
// 빌드된 실행파일의 경우 서버들의 하드웨어, 커널버전 등이 동일하다면 실행파일만 배포하고, 아니라면 각 서버마다 빌드를 해줘야 함.
```

## 설정파일
- 설정파일 수정 전에 먼저 secret file을 생성해줘야 함.
```
// core-site.xml의 hadoop.http.authentication.signature.secret.file property에 지정할 secret 파일 생성
[root@vm111]# dd if=/dev/urandom of=/home/fbpuser/hadoop-2.4.1/etc/hadoop/hadoop-http-auth-signature-secret bs=1024 count=1

// 퍼미션 설정
// 데몬을 실행시킬 user 소유로 변경
// 아래는 hdfs 라는 user로 데몬들을 실행시킨다는 가정
[root@vm111]# chown fbpuser:fbpgroup /home/fbpuser/hadoop-2.4.1/etc/hadoop/hadoop-http-auth-signature-secret
[root@vm111]# chmod 400 /home/fbpuser/hadoop-2.4.1/etc/hadoop/hadoop-http-auth-signature-secret

// 생성 후 전체 서버 배포
scp /home/fbpuser/hadoop-2.4.1/etc/hadoop/hadoop-http-auth-signature-secret vm112:/home/fbpuser/hadoop-2.4.1/etc/hadoop/
```

-  설정파일 수정
```
vi ${HADOOP_HOME}/etc/hadoop/core-site.xml
<!-- 보안설정 -->
<property>
    <name>hadoop.security.authentication</name>
    <value>kerberos</value>
</property>
<property>
    <name>hadoop.security.authorization</name>
    <value>true</value>
</property>
<property>
    <name>hadoop.rpc.protection</name>
    <value>privacy</value>
</property>
 
<!-- SPNEGO/Kerberos - 웹접속 관련 보안설정 -->
<property>
    <name>hadoop.http.filter.initializers</name>
    <value>org.apache.hadoop.security.AuthenticationFilterInitializer</value>
</property>
<property>
    <name>hadoop.http.authentication.type</name>
    <value>kerberos</value>
</property>
<property>
    <name>hadoop.http.authentication.token.validity</name>
    <value>36000</value>
</property>
<property>
    <name>hadoop.http.authentication.signature.secret.file</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/hadoop-http-auth-signature-secret</value>
</property>
<property>
    <name>hadoop.http.authentication.cookie.domain</name>
    <value>kocap.com</value>
</property>
<property>
    <name>hadoop.http.authentication.simple.anonymous.allowed</name>
    <value>false</value>
</property>
<property>
    <name>hadoop.http.authentication.kerberos.principal</name>
    <value>HTTP/_HOST@KOCAP.COM</value>
</property>
<property>
    <name>hadoop.http.authentication.kerberos.keytab</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab</value>
</property>
 
<!-- Encrypted Shuffle - Map->Reduce 데이터 전달시 암호화 -->
<property>
    <name>hadoop.ssl.require.client.cert</name>
    <value>false</value>
    <final>true</final>
</property>
<property>
    <name>hadoop.ssl.hostname.verifier</name>
    <value>DEFAULT</value>
    <final>true</final>
</property>
<property>
    <name>hadoop.ssl.keystores.factory.class</name>
    <value>org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory</value>
    <final>true</final>
</property>
<property>
    <name>hadoop.ssl.server.conf</name>
    <value>ssl-server.xml</value>
    <final>true</final>
</property>
<property>
    <name>hadoop.ssl.client.conf</name>
    <value>ssl-client.xml</value>
    <final>true</final>
</property>


vi ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
<!-- SECURITY -->
<property>
    <name>dfs.block.access.token.enable</name>
    <value>true</value>
</property>
<property>
    <name>dfs.data.transfer.protection</name>
    <value>privacy</value>
</property>
<property>
    <name>dfs.http.policy</name>
    <value>HTTPS_ONLY</value>
</property>
<!-- JournalNode -->
<property>
    <name>dfs.journalnode.keytab.file</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab</value>
</property>
<property>
    <name>dfs.journalnode.kerberos.principal</name>
    <value>hdfs/_HOST@KOCAP.COM</value>
</property>
<property>
    <name>dfs.journalnode.kerberos.internal.spnego.principal</name>
    <value>HTTP/_HOST@KOCAP.COM</value>
</property>
<!-- NameNode -->
<property>
    <name>dfs.namenode.https-address.hadoop-cluster.nn1</name>
    <value>vm111:50470</value>
</property>
<property>
    <name>dfs.namenode.https-address.hadoop-cluster.nn2</name>
    <value>vm112:50470</value>
</property>
<property>
    <name>dfs.namenode.keytab.file</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab</value>
</property>
<property>
    <name>dfs.namenode.kerberos.principal</name>
    <value>hdfs/_HOST@KOCAP.COM</value>
</property>
<property>
    <name>dfs.namenode.kerberos.internal.spnego.principal</name>
    <value>${dfs.web.authentication.kerberos.principal}</value>
</property>
<!-- DataNode -->
<property>
    <name>dfs.datanode.data.dir.perm</name>
    <value>700</value>
</property>
<property>
    <name>dfs.datanode.https.address</name>
    <value>0.0.0.0:50475</value>
</property>
<property>
    <name>dfs.datanode.keytab.file</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab</value>
</property>
<property>
    <name>dfs.datanode.kerberos.principal</name>
    <value>hdfs/_HOST@KOCAP.COM</value>
</property>
<!-- Web -->
<property>
    <name>dfs.web.authentication.kerberos.keytab</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab</value>
</property>
<property>
    <name>dfs.web.authentication.kerberos.principal</name>
    <value>HTTP/_HOST@KOCAP.COM</value>
</property>


vi ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
<!-- JobHistoryServer 보안설정 -->
<property>
    <name>mapreduce.jobhistory.keytab</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/hdfs.keytab</value>
</property>
<property>
    <name>mapreduce.jobhistory.principal</name>
    <value>hdfs/_HOST@KOCAP.COM</value>
</property>
<property>
    <name>mapreduce.jobhistory.http.policy</name>
    <value>HTTPS_ONLY</value>
</property>
<property>
    <name>mapreduce.jobhistory.webapp.https.address</name>
    <value>vm111:19888</value>
</property>
<!-- Map/Reduce Shuffle SSL 설정 -->
<property>
    <name>mapreduce.shuffle.ssl.enabled</name>
    <value>true</value>
    <final>true</final>
</property>



vi ${HADOOP_HOME}/etc/hadoop/yarn-site.xml
<!-- ResourceManager 보안설정 -->
<property>
    <name>yarn.resourcemanager.keytab</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/yarn.keytab</value>
</property>
<property>
    <name>yarn.resourcemanager.principal</name>
    <value>yarn/_HOST@KOCAP.COM</value>
</property>
<!-- NodeManager 보안설정 -->
<property>
    <name>yarn.nodemanager.keytab</name>
    <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/yarn.keytab</value>
</property>
<property>
    <name>yarn.nodemanager.principal</name>
    <value>yarn/_HOST@KOCAP.COM</value>
</property>
<!-- ContainerExecutor 관련 -->
<property>
    <name>yarn.nodemanager.container-executor.class</name>
    <value>org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor</value>
</property>
<property>
    <name>yarn.nodemanager.linux-container-executor.group</name>
    <value>fbpuser</value>
</property>
<property>
    <name>yarn.nodemanager.linux-container-executor.path</name>
    <value>/home/fbpuser/hadoop-2.4.1/bin/container-executor</value>
</property>
<!-- WEB 관련 -->
<property>
    <name>yarn.http.policy</name>
    <value>HTTPS_ONLY</value>
</property>
<property>
    <name>yarn.resourcemanager.webapp.https.address</name>
    <value>0.0.0.0:8090</value>
</property>
<property>
    <name>yarn.nodemanager.webapp.https.address</name>
    <value>0.0.0.0:8042</value>
</property>
<property>
    <name>yarn.log.server.url</name>
    <value>https://vm111:19888/jobhistory/logs</value>
</property>
```


## SSL 인증서 만들기
- 보안통신을 위한 SSL 인증서가 필요함.
- Third party의 진짜 리얼 인증서를 이용하거나, self-signed 를 이용하는 방법도 있음.
- Openssl을 이용한 internal CA를 이용하는 방법을 사용함.
```
// internal CA setup
[root@vm111]# openssl genrsa -out ca.key 8192
[root@vm111]# openssl req -new -x509 -extensions v3_ca -key ca.key -out ca.crt -days 18250
[root@vm111]# mkdir -m 0700 /root/CA /root/CA/certs /root/CA/crl /root/CA/newcerts /root/CA/private
[root@vm111]# mv ca.key /root/CA/private
[root@vm111]# mv ca.crt /root/CA/certs
[root@vm111]# touch /root/CA/index.txt ; echo 1000 >> /root/CA/serial
[root@vm111]# chmod 0400 /root/CA/private/ca.key

// openssl 설정파일 수정
[root@vm111]# vi /etc/pki/tls/openssl.cnf

#######################################################################################
[ CA_default ]

dir         = /root/CA          # Where everything is kept
certs       = $dir/certs        # Where the issued certs are kept
crl_dir     = $dir/crl          # Where the issued crl are kept
database    = $dir/index.txt    # database index file.
#unique_subject = no            # Set to 'no' to allow creation of
                                # several ctificates with same subject.
new_certs_dir = $dir/newcerts   # default place for new certs.

certificate = $dir/cacert.pem   # The CA certificate
serial      = $dir/serial       # The current serial number
crlnumber   = $dir/crlnumber    # the current crl number
                                # must be commented out to leave a V1 CRL
crl         = $dir/crl.pem           # The current CRL
private_key = $dir/private/cakey.pem # The private key
RANDFILE    = $dir/private/.rand     # private random number file

x509_extensions = usr_cert      # The extentions to add to the cert
#######################################################################################

// cluster trust store 
[root@vm111]# openssl genrsa -out clusterCA.key 2048
[root@vm111]# openssl req -x509 -new -key clusterCA.key -days 18250 -out clusterCA.pem
[root@vm111]# keytool -importcert -alias clusterCA -file clusterCA.pem -keystore clusterTrustStore -storepass "비밀번호"

[root@vm111]# mkdir /home/fbpuser/hadoop-2.4.1/etc/hadoop/security
[root@vm111]# mv clusterCA.key clusterCA.pem clusterTrustStore /home/fbpuser/hadoop-2.4.1/etc/hadoop/security
[root@vm111]# cd /home/fbpuser/hadoop-2.4.1/etc/hadoop/security

// host key store
[root@vm111]# keytool -genkeypair -alias `hostname -s` -keyalg RSA -keysize 1024 -dname "CN=`hostname -f`,OU=foo,O=corp" -keypass "비밀번호" -keystore hostKeyStore -storepass "비밀번호" -validity 18250
[root@vm111]# keytool -keystore hostKeyStore -alias `hostname -s` -certreq -file host.cert -storepass "비밀번호" -keypass "비밀번호"
[root@vm111]# openssl x509 -req -CA clusterCA.pem -CAkey clusterCA.key -in host.cert -out host.signed -days 18250 -CAcreateserial
[root@vm111]# keytool -keystore hostKeyStore -storepass "비밀번호" -alias clusterCA -import -file clusterCA.pem 
[root@vm111]# keytool -keystore hostKeyStore -storepass "비밀번호" -alias `hostname -s` -import -file host.signed -keypass "비밀번호"

// 나머지 전체 서버들 동일하게 세팅
// 전체 서버 대상으로
// 디렉토리 만들고
[root@vm111]# ssh root@vm112 mkdir -p /home/fbpuser/hadoop-2.4.1/etc/hadoop/security
// 필요한 파일 전송
[root@vm111]# scp clusterCA.key clusterCA.pem clusterTrustStore root@vm112:/home/fbpuser/hadoop-2.4.1/etc/hadoop/security

// 각 서버별 key store 생성 
[root@vm112]# export JAVA_HOME=/usr/java/latest
[root@vm112]# export PATH=$PATH:$JAVA_HOME:$JAVA_HOME/bin
[root@vm112]# cd /home/fbpuser/hadoop-2.4.1/etc/hadoop/security
[root@vm112]# keytool -genkeypair -alias `hostname -s` -keyalg RSA -keysize 1024 -dname "CN=`hostname -f`,OU=foo,O=corp" -keypass "비밀번호" -keystore hostKeyStore -storepass "비밀번호" -validity 18250
[root@vm112]# keytool -keystore hostKeyStore -alias `hostname -s` -certreq -file host.cert -storepass "비밀번호" -keypass "비밀번호"
[root@vm112# openssl x509 -req -CA clusterCA.pem -CAkey clusterCA.key -in host.cert -out host.signed -days 18250 -CAcreateserial
[root@vm112]# keytool -keystore hostKeyStore -storepass "비밀번호" -alias clusterCA -import -file clusterCA.pem 
[root@vm112]# keytool -keystore hostKeyStore -storepass "비밀번호" -alias `hostname -s` -import -file host.signed -keypass "비밀번호"
```

- SSL 관련 설정파일 세팅
```
// 예제 파일을 복사해서 설정파일로 사용함.
[root@vm111]# cd /home/fbpuser/hadoop-2.4.1/etc/hadoop
[root@vm111]# cp ssl-client.xml.example ssl-client.xml
[root@vm111]# cp ssl-server.xml.example ssl-server.xml
[root@vm111]# vi ssl-client.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>ssl.client.truststore.location</name>
  <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/security/clusterTrustStore</value>
</property>
<property>
  <name>ssl.client.truststore.password</name>
  <value>비밀번호</value>
</property>
<property>
  <name>ssl.client.truststore.type</name>
  <value>jks</value>
</property>
<property>
  <name>ssl.client.truststore.reload.interval</name>
  <value>10000</value>
</property>
<property>
  <name>ssl.client.keystore.location</name>
  <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/security/hostKeyStore</value>
</property>
<property>
  <name>ssl.client.keystore.password</name>
  <value>비밀번호</value>
</property>
<property>
  <name>ssl.client.keystore.keypassword</name>
  <value>비밀번호</value>
</property>
<property>
  <name>ssl.client.keystore.type</name>
  <value>jks</value>
</property>
 
</configuration>


[root@vm111]# vi ssl-server.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
 
<configuration>
 
<property>
  <name>ssl.server.truststore.location</name>
  <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/security/clusterTrustStore</value>
</property>
<property>
  <name>ssl.server.truststore.password</name>
  <value>비밀번호</value>
</property>
<property>
  <name>ssl.server.truststore.type</name>
  <value>jks</value>
</property>
<property>
  <name>ssl.server.truststore.reload.interval</name>
  <value>10000</value>
</property>
<property>
  <name>ssl.server.keystore.location</name>
  <value>/home/fbpuser/hadoop-2.4.1/etc/hadoop/security/hostKeyStore</value>
</property>
<property>
  <name>ssl.server.keystore.password</name>
  <value>비밀번호</value>
</property>
<property>
  <name>ssl.server.keystore.keypassword</name>
  <value>비밀번호</value>
</property>
<property>
  <name>ssl.server.keystore.type</name>
  <value>jks</value>
</property>
 
</configuration>


##설정 후 ssl-client.xml과 ssl-server.xml을 전체 서버에 배포.
[root@vm111]# scp ssl-server.xml vm112:/home/fbpuser/hadoop-2.4.1/etc/hadoop/
[root@vm111]# scp ssl-client.xml vm112:/home/fbpuser/hadoop-2.4.1/etc/hadoop/
```


## 확인
- 클러스터 재시작


- 아래와 같이 에러가 발생함.
- keystore생성 단계에서는 에러가 발생하지 않았음. ?????????
```
java.io.FileNotFoundException: /home/fbpuser/.keystore
```




