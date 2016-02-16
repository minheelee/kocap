
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
- 


## container-executor 빌드


## 설정파일
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
    <value>/home/hadoop/etc/hadoop/hadoop-http-auth-signature-secret</value>
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
















