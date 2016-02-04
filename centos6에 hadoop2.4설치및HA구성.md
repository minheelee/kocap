
# CentOS6에 Hadoop2.4설치 및 HA구성

rm -rf ~/.ssh/
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub localhost
ssh-copy-id -i ~/.ssh/id_rsa.pub vm111.kocap.com ~ vm211.kocap.com

pscp -h ~/hosts.txt ~/.ssh/authorized_keys  ~/.ssh/ 
pscp -h ~/hosts.txt ~/.ssh/id_rsa  ~/.ssh/
pscp -h ~/hosts.txt ~/.ssh/id_rsa.pub  ~/.ssh/
pscp -h ~/hosts.txt ~/.ssh/known_hosts  ~/.ssh/

pssh -h ~/hosts.txt service iptables stop
pssh -h ~/hosts.txt chkconfig iptables off

pssh -h ~/all_hosts.txt  groupadd fbpgroup 
pssh -h ~/all_hosts.txt  adduser -p pagVZlVnu4OOs -g fbpgroup -d /home/fbpuser fbpuser


su fbpuser
cd
cat > ~/hosts.txt <<HOSTS
vm111.kocap.com
vm112.kocap.com
vm211.kocap.com
vm212.kocap.com
HOSTS

rm -rf ~/.ssh/
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub vm111.kocap.com ~ vm211.kocap.com
비번 : fbppasswd0
pscp -h ~/hosts.txt ~/.ssh/authorized_keys  ~/.ssh/ 
pscp -h ~/hosts.txt ~/.ssh/id_rsa  ~/.ssh/
pscp -h ~/hosts.txt ~/.ssh/id_rsa.pub  ~/.ssh/
pscp -h ~/hosts.txt ~/.ssh/known_hosts  ~/.ssh/

## java 설치
- root 권한으로
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/java/jdk-7u79-linux-x64.rpm ~/ 
pssh -h ~/hosts.txt  rpm -Uvh ~/jdk-7u79-linux-x64.rpm  


pssh -h ~/hosts.txt "echo 'export JAVA_HOME=/usr/java/latest' >> ~/.bash_profile "
pssh -h ~/hosts.txt "echo 'export PATH=$PATH:$JAVA_HOME:$JAVA_HOME/bin' >> ~/.bash_profile "


## hadooop HA 설정
- 출처 : http://satis.tistory.com/8
- 출처 : https://jaebfactory.wordpress.com/2013/04/25/hadoop-2-0-namenode-high-availability/

vi ~/.bash_profile
```
export HADOOP_HOME=/home/fbpuser/hadoop-2.4.1
export HADOOP_LOG_DIR="${HADOOP_HOME}/logs"
export HADOOP_MAPRED_HOME=${HADOOP_HOME}
export HADOOP_COMMON_HOME=${HADOOP_HOME}
export HADOOP_HDFS_HOME=${HADOOP_HOME}
export HADOOP_YARN_HOME=${HADOOP_HOME}

source ~/.bash_profile
```

vi ${HADOOP_HOME}/etc/hadoop/slaves
```
vm111
vm112
vm211
vm212
```

vi ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
```
export JAVA_HOME=/usr/java/latest

export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
```

vi ${HADOOP_HOME}/etc/hadoop/yarn-env.sh
```
export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
```


vi ${HADOOP_HOME}/etc/hadoop/core-site.xml
```
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://vm111</value>
    </property>
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>vm111:2181,vm112:2181,vm211:2181,vm212:2181</value>
    </property>
</configuration>
```

vi ${HADOOP_HOME}/etc/hadoop/yarn-site.xml
```
<configuration>
<!-- Site specific YARN configuration properties -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <description>Classpath for typical applications.</description>
        <name>yarn.application.classpath</name>
        <value>
            $HADOOP_CONF_DIR,
            $HADOOP_COMMON_HOME/*,$HADOOP_COMMON_HOME/lib/*,
            $HADOOP_HDFS_HOME/*,$HADOOP_HDFS_HOME/lib/*,
            $HADOOP_MAPRED_HOME/*,$HADOOP_MAPRED_HOME/lib/*,
            $YARN_HOME/*,$YARN_HOME/lib/*
        </value>
    </property>

    <property>
        <name>yarn.resourcemanager.connect.retry-interval.ms</name>
        <value>2000</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>resourcemanager-cluster</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>vm111</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>vm112</value>
    </property>
    <property>
        <name>yarn.resourcemanager.zk-address</name>
        <value>vm111:2181,vm112:2181,vm211:2181,vm212:2181</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.automatic-failover.embedded</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.client.failover-proxy-provider</name>
        <value>org.apache.hadoop.yarn.client.ConfiguredRMFailoverProxyProvider</value>
    </property>
    <property>
        <name>yarn.resourcemanager.store.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.automatic-failover.zk-base-path</name>
        <value>/yarn-leader-election</value>
        <description>Optional setting. The default value is /yarn-leader-election</description>
    </property>
    <property>
        <name>yarn.resourcemanager.recovery.enabled</name>
        <value>true</value>
    </property>

    <!-- RM1 Configs -->
    <property>
        <name>yarn.resourcemanager.address.rm1</name>
        <value>vm111:23140</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm1</name>
        <value>vm111:23130</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm1</name>
        <value>vm111:23188</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm1</name>
        <value>vm111:23125</value>
    </property>
    <property>
        <name>yarn.resourcemanager.admin.address.rm1</name>
        <value>vm111:23141</value>
    </property>

    <!-- RM2 configs -->
    <property>
        <name>yarn.resourcemanager.address.rm2</name>
        <value>vm112:23140</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm2</name>
        <value>vm112:23130</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm2</name>
        <value>vm112:23188</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm2</name>
        <value>vm112:23125</value>
    </property>
    <property>
        <name>yarn.resourcemanager.admin.address.rm2</name>
        <value>vm112:23141</value>
    </property>
</configuration>
```


mv ${HADOOP_HOME}/etc/hadoop/mapred-site.xml.template ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
vi ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
```
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>

    <property>
        <name>mapred.system.dir</name>
        <value>file:/home/fbpuser/data/hadoop/repository/mapred/system</value>
        <final>true</final>
    </property>

    <property>
        <name>mapred.local.dir</name>
        <value>file:/home/fbpuser/data/hadoop/repository/mapred/local</value>
        <final>true</final>
    </property>
</configuration>
```


vi ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
```
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>    
    <property>
        <name>dfs.name.dir</name>
        <value>file:/home/fbpuser/data/hadoop/repository/dfs/name</value>
        <final>true</final>
    </property>
    <property>
        <name>dfs.data.dir</name>
        <value>file:/home/fbpuser/data/hadoop/repository/dfs/data</value>
        <final>true</final>
    </property>
    <property>
        <name>fs.hdfs.impl</name>
        <value>org.apache.hadoop.hdfs.DistributedFileSystem</value>
        <description>The FileSystem for hdfs: uris.</description>
    </property>

    <!-- common server name -->
    <property>
        <name>dfs.nameservices</name>
        <value>hadoop-cluster</value>
    </property>
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>/home/fbpuser/data/hadoop/jn</value>
    </property>

    <!-- HA configuration -->
    <property>
        <name>dfs.ha.namenodes.hadoop-cluster</name>
        <value>nn1,nn2</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.hadoop-cluster.nn1</name>
        <value>vm111:8020</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.hadoop-cluster.nn2</name>
        <value>vm112:8020</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.hadoop-cluster.nn1</name>
        <value>vm111:50070</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.hadoop-cluster.nn2</name>
        <value>vm112:50070</value>
    </property>

    <!-- Storage for edits' files -->
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://vm111:8485;vm112:8485;vm211:8485/hadoop-cluster</value>
    </property>
    <property>
        <name>dfs.namenode.max.extra.edits.segments.retained</name>
        <value>1000000</value>
    </property>

    <!-- Client failover -->
    <property>
        <name>dfs.client.failover.proxy.provider.ha-nn</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>

    <!-- Fencing configuration -->
    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>shell(/home/fbpuser/zookeeper-3.4.6/bin/zkServer.sh --nameservice=hadoop-cluster vm111:8485)</value>
    </property>

    <!-- Automatic failover configuration -->
    <property>
        <name>dfs.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property>
</configuration>
```

vi ${HADOOP_HOME}/etc/hadoop/journalnodes
```
vm111
vm112
```


scp -r ~/hadoop-2.4.1  vm112:~/


## hadooop 실행

- namenode 서버에서 실행
$HADOOP_HOME/bin/hdfs zkfc -formatZK

- QJM로 사용할 서버마다 JournalNode 를 실행( vm111, vm112 )
${HADOOP_HOME}/sbin/hadoop-daemon.sh start journalnode  

 - namenode(active namenode)에서 실행
${HADOOP_HOME}/bin/hdfs namenode -format

- namenode(standby  namenode)에서 실행
$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby

 - namenode(active namenode)에서 실행
$HADOOP_HOME/sbin/start-all.sh

- namenode(standby  namenode)에서 실행
$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode
 
- active / standby namenode에 zkfc를 실행
$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc

- primary namenode가 active가 아니라 standby일 경우 다음과 같이 명령을 수행해서 active로 바꾼다.
$HADOOP_HOME/bin/hdfs haadmin -transitionToActive nn1

- standby resourcemanager 실행
$HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager
$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver

- namenode Active/Standby 확인
$HADOOP_HOME/bin/hdfs haadmin -transitionToActive ( nn1 or nn2 ) 

- ResourceManager Active/Standby 확인
$HADOOP_HOME/bin/yarn rmadmin -getServiceState (rm1 or rm2)


## Kerberos 설정
- 출처 : http://bloodguy.tistory.com/954
- Kerberos는 fault tolerance를 위해 replication을 제공함.
- master-slave(s)로 구성되며, 평소에는 master에서 다 처리하고 주기적으로 master의 db를 slave(s)에 sync하는 방식으로 유지되다가, master가 죽으면 slave가 처리하는 방식.
    - 1. 서버는 master(vm111.kocap.com), slave(vm111.kocap.com)로 구성.
    - 2. hostname은 kocap.com이며 realm은 KOCAP.COM
    - 3. centos 기준

- root 권한으로
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/portreserve-0.0.4-9.el6.x86_64.rpm  ~/ 
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/words-3.0-17.el6.noarch.rpm  ~/
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/krb5-server-1.10.3-42.el6.x86_64.rpm  ~/
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/krb5-libs-1.10.3-42.el6.x86_64.rpm  ~/
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/kerberos/krb5-workstation-1.10.3-42.el6.x86_64.rpm  ~/

pssh -h ~/hosts.txt  rpm -Uvh portreserve-0.0.4-9.el6.x86_64.rpm
pssh -h ~/hosts.txt  rpm -Uvh words-3.0-17.el6.noarch.rpm
pssh -h ~/hosts.txt  rpm -Uvh krb5-server-1.10.3-42.el6.x86_64.rpm
pssh -h ~/hosts.txt  rpm -Uvh krb5-libs-1.10.3-42.el6.x86_64.rpm
pssh -h ~/hosts.txt  rpm -Uvh krb5-workstation-1.10.3-42.el6.x86_64.rpm


vi /etc/krb5.conf
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
  kdc = vm111.kocap.com:88
  kdc = vm112.kocap.com:88
  admin_server = vm111.kocap.com:749
  default_domain = kocap.com
 }

[domain_realm]
 .kocap.com = KOCAP.COM
 kocap.com = KOCAP.COM
```

vi /var/kerberos/krb5kdc/kdc.conf
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

- Database 생성
```
kdb5_util create -s
```

- vi /var/kerberos/krb5kdc/kadm5.acl
```
*/admin@KOCAP.COM       *
```

- kadmin.local -q "addprinc admin/admin"
- service krb5kdc start




## hadoop Kerberos 설정 
- 출처 : http://bloodguy.tistory.com/entry/Hadoop-%EB%B3%B4%EC%95%88%EC%84%A4%EC%A0%95-security-kerberos-spnego-ssl











