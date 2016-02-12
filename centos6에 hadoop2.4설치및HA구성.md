
# CentOS6에 Hadoop2.4설치 및 HA구성

## 설치용 패키지 받기
```
mkdir -p /home/kvm/kocap/
cd /home/kvm/kocap/
svn co  svn://xxx.xxx.xxx.xxx/NGT/BigData/Sources/HadoopMonitoring/installer2.4  --username  ID  --password 비번
cd installer2.4 
```

## Native LIB 만들기

### 빌드도구 설치
```
yum install libgcc_s.so.1 gcc-c++ cmake openssl-devel -y
 
cd /home/kvm/kocap/installer2.4/rpm/hadoop
wget http://protobuf.googlecode.com/files/protobuf-2.5.0.tar.gz
tar -zxvf protobuf-2.5.0.tar.gz
cd protobuf-2.5.0
./configure --prefix=/usr/local/lib/protobuf-2.5.0
make && make install
export PATH=$PATH:/usr/local/lib/protobuf-2.5.0/bin


cd /home/kvm/kocap/installer2.4/rpm/hadoop
wget http://apache.mirror.cdnetworks.com/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
tar xvf apache-maven-3.0.5-bin.tar.gz
ln -s /home/kvm/kocap/installer2.4/rpm/hadoop/apache-maven-3.0.5 /usr/local/maven
export PATH=/usr/local/maven/bin:$PATH
mvn -version
```

### Snappy 설치
```
cd /home/kvm/kocap/installer2.4/rpm/hadoop
wget https://github.com/google/snappy/releases/download/1.1.3/snappy-1.1.3.tar.gz
tar xvf snappy-1.1.3.tar.gz
cd snappy-1.1.3
./configure && make && make install
```

### 하둡 빌드
```
cd /home/kvm/kocap/installer2.4/rpm/hadoop
wget https://archive.apache.org/dist/hadoop/common/hadoop-2.4.1/hadoop-2.4.1-src.tar.gz
tar xvfz hadoop-2.4.1-src.tar.gz
cd hadoop-2.4.1-src
mvn package -Pdist,native -DskipTests -Dtar
mv hadoop-dist/target/hadoop-2.4.1/lib/native  ../hadoop-2.4.1_lib_native
cp /usr/local/lib/libsnappy*  ../hadoop-2.4.1_lib_native/
```

## 준비 

- localhost 에서    root 권한
```
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

userdel -r  fbpuser 
groupdel fbpgroup

pssh -h ~/all_hosts.txt  groupadd fbpgroup 
pssh -h ~/all_hosts.txt  adduser -p pagVZlVnu4OOs -g fbpgroup -d /home/fbpuser fbpuser


su fbpuser
cd
cat > ~/hosts.txt <<HOSTS
vm111
vm112
vm211
vm212
HOSTS

rm -rf ~/.ssh/
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub vm111 ~ vm211
비번 : fbppasswd0
pscp -h ~/hosts.txt ~/.ssh/authorized_keys  ~/.ssh/ 
pscp -h ~/hosts.txt ~/.ssh/id_rsa  ~/.ssh/
pscp -h ~/hosts.txt ~/.ssh/id_rsa.pub  ~/.ssh/
pscp -h ~/hosts.txt ~/.ssh/known_hosts  ~/.ssh/
```

## java 설치
- root 권한으로
```
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/java/jdk-7u79-linux-x64.rpm ~/ 
pssh -h ~/hosts.txt  rpm -Uvh ~/jdk-7u79-linux-x64.rpm  

### kerberos인증을 위해서 Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files로 업데이터가 필요함.
### kerberos인증을 하지 않으면 필요없음.
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/java/UnlimitedJCEPolicyJDK7/US_export_policy.jar  /usr/java/latest/jre/lib/security
pscp -h ~/hosts.txt  /home/kvm/kocap/installer2.4/rpm/java/UnlimitedJCEPolicyJDK7/local_policy.jar      /usr/java/latest/jre/lib/security


- vm111에 su fbpuser 으로 사용자 권한으로
vi ~/.bash_profile
export JAVA_HOME=/usr/java/latest
export PATH=$PATH:$JAVA_HOME:$JAVA_HOME/bin
```


## Zookeeper 설정
- su fbpuser 으로 사용자 권한으로

```
scp /home/kvm/kocap/installer2.4/rpm/zookeeper/zookeeper-3.4.6.tar.gz    vm111:~/
ssh vm111
tar  xvf  zookeeper-3.4.6.tar.gz


vi ~/.bash_profile
export ZOOKEEPER_HOME=/home/fbpuser/zookeeper-3.4.6
source ~/.bash_profile


cp ${ZOOKEEPER_HOME}/conf/zoo_sample.cfg    ${ZOOKEEPER_HOME}/conf/zoo.cfg
vi ${ZOOKEEPER_HOME}/conf/zoo.cfg
dataDir=/home/fbpuser/data/zookeeper
server.1=vm111:2888:3888
server.2=vm112:2888:3888
server.3=vm211:2888:3888



mkdir -p /home/fbpuser/data/zookeeper
echo 1 > /home/fbpuser/data/zookeeper/myid

scp -r /home/fbpuser/data    vm112:~/ 
scp -r /home/fbpuser/data    vm211:~/
scp -r /home/fbpuser/data    vm212:~/

scp -r ${ZOOKEEPER_HOME}    vm112:~/
scp -r ${ZOOKEEPER_HOME}    vm211:~/
scp -r ${ZOOKEEPER_HOME}    vm212:~/

ssh vm112 "echo 2 > /home/fbpuser/data/zookeeper/myid"
ssh vm211 "echo 3 > /home/fbpuser/data/zookeeper/myid"
ssh vm212 "echo 4 > /home/fbpuser/data/zookeeper/myid"

${ZOOKEEPER_HOME}/bin/zkServer.sh start
ssh vm112 "${ZOOKEEPER_HOME}/bin/zkServer.sh start " 
ssh vm211 "${ZOOKEEPER_HOME}/bin/zkServer.sh start "
```

## hadooop HA 설정
- 출처 : http://satis.tistory.com/8
- 출처 : https://jaebfactory.wordpress.com/2013/04/25/hadoop-2-0-namenode-high-availability/


- su fbpuser 으로 사용자 권한으로

```
scp    /home/kvm/kocap/installer2.4/rpm/hadoop/hadoop-2.4.1.tar.gz    vm111:~/
scp -r /home/kvm/kocap/installer2.4/rpm/hadoop/hadoop-2.4.1_lib_native vm111:~/
ssh vm111
tar  xvf  hadoop-2.4.1.tar.gz
cp ~/hadoop-2.4.1_lib_native/*  ~/hadoop-2.4.1/lib/native/
 

vi ~/.bash_profile
export HADOOP_HOME=/home/fbpuser/hadoop-2.4.1
export HADOOP_LOG_DIR="${HADOOP_HOME}/logs"
export HADOOP_MAPRED_HOME=${HADOOP_HOME}
export HADOOP_COMMON_HOME=${HADOOP_HOME}
export HADOOP_HDFS_HOME=${HADOOP_HOME}
export HADOOP_YARN_HOME=${HADOOP_HOME}
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin


source ~/.bash_profile

vi ${HADOOP_HOME}/etc/hadoop/slaves
vm111
vm112
vm211
vm212


vi ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
# export JAVA_HOME=${JAVA_HOME}
export JAVA_HOME=/usr/java/latest
export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"


vi ${HADOOP_HOME}/etc/hadoop/yarn-env.sh
export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"


${HADOOP_HOME}/bin/hadoop checknative  # Check Native

vi ${HADOOP_HOME}/etc/hadoop/core-site.xml
<configuration>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/home/fbpuser/data/hadoop/tmp</value>
    </property>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://cap-hadoop-cluster</value>
    </property>
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>/home/fbpuser/data/hadoop/jn</value>
    </property>
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>vm111:2181,vm112:2181,vm211:2181</value>
    </property>
</configuration>


vi ${HADOOP_HOME}/etc/hadoop/yarn-site.xml
<configuration>
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
        <value>vm111:2181,vm112:2181,vm211:2181</value>
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


mv ${HADOOP_HOME}/etc/hadoop/mapred-site.xml.template ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
vi ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
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


vi ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
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
        <value>cap-hadoop-cluster</value>
    </property>


    <!-- HA configuration -->
    <property>
        <name>dfs.ha.namenodes.cap-hadoop-cluster</name>
        <value>nn1,nn2</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.cap-hadoop-cluster.nn1</name>
        <value>vm111:8020</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.cap-hadoop-cluster.nn2</name>
        <value>vm112:8020</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.cap-hadoop-cluster.nn1</name>
        <value>vm111:50070</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.cap-hadoop-cluster.nn2</name>
        <value>vm112:50070</value>
    </property>

    <!-- Storage for edits' files -->
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://vm111:8485;vm112:8485;vm211:8485/cap-hadoop-cluster</value>
    </property>
    <property>
        <name>dfs.namenode.max.extra.edits.segments.retained</name>
        <value>1000000</value>
    </property>

    <!-- Client failover -->
    <property>
        <name>dfs.client.failover.proxy.provider.cap-hadoop-cluster</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>

    <!-- Fencing configuration -->
    <property>
      <name>dfs.ha.fencing.methods</name>
      <value>sshfence</value>
    </property>
    <property>
      <name>dfs.ha.fencing.ssh.private-key-files</name>
      <value>/home/fbpuser/.ssh/id_rsa</value>
    </property>

    <!-- Automatic failover configuration -->
    <property>
        <name>dfs.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property>
</configuration>


vi ${HADOOP_HOME}/etc/hadoop/journalnodes
vm111
vm112
vm211


scp -r ~/.bash_profile  vm112:~/
scp -r ~/.bash_profile  vm211:~/
scp -r ~/.bash_profile  vm212:~/

scp -r ${HADOOP_HOME}  vm112:~/
scp -r ${HADOOP_HOME}  vm211:~/
scp -r ${HADOOP_HOME}  vm212:~/

```

## Hadooop 실행

- zookeeper에 HA를 위한 znode를 추가, namenode 서버에서 실행
```
$HADOOP_HOME/bin/hdfs zkfc -formatZK
```

- QJM로 사용할 서버마다 JournalNode 를 실행( vm111, vm112, vm211 )
```
${HADOOP_HOME}/sbin/hadoop-daemon.sh start journalnode
```  

- namenode(active namenode)에서 실행
```
${HADOOP_HOME}/bin/hdfs namenode -format
```

- namenode(active namenode)에서 실행
```
$HADOOP_HOME/sbin/start-all.sh
```

- namenode(standby  namenode)에서 실행
```
$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby
```

- namenode(standby  namenode)에서 실행
```
$HADOOP_HOME/sbin/hadoop-daemon.sh start namenode
```
 
- active / standby namenode에 zkfc를 실행
```
$HADOOP_HOME/sbin/hadoop-daemon.sh start zkfc
```

- primary namenode가 active가 아니라 standby일 경우 다음과 같이 명령을 수행해서 active로 바꾼다.
```
$HADOOP_HOME/bin/hdfs haadmin -transitionToActive nn1
```

- standby resourcemanager 실행
```
$HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager
$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver
```

- namenode Active/Standby 확인
```
$HADOOP_HOME/bin/hdfs haadmin -getServiceState ( nn1 or nn2 ) 
```

- ResourceManager Active/Standby 확인
```
$HADOOP_HOME/bin/yarn rmadmin -getServiceState (rm1 or rm2)
```


## hadoop Kerberos 설정 
- 출처 : http://bloodguy.tistory.com/entry/Hadoop-%EB%B3%B4%EC%95%88%EC%84%A4%EC%A0%95-security-kerberos-spnego-ssl











