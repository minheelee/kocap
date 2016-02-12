
# Zookeeper에 Kerberos보안설정하는방법
- 사전 작업
    - centos6에 [Kerberos보안설정.md](https://github.com/minheelee/kocap/blob/master/centos6%EC%97%90%20Kerberos%EB%B3%B4%EC%95%88%EC%84%A4%EC%A0%95.md)
    - centos6에 [hadoop2.4설치및HA구성.md](https://github.com/minheelee/kocap/blob/master/centos6%EC%97%90%20hadoop2.4%EC%84%A4%EC%B9%98%EB%B0%8FHA%EA%B5%AC%EC%84%B1.md) 에서 zookeeper 설치 참조

- 출처 : http://bloodguy.tistory.com/957

## Zookeeper 서버 설정

- principal, keytab 파일생성
```
[root@vm111]# kadmin  -p admin/admin
// principal 추가
kadmin: addprinc -randkey zookeeper/vm111@KOCAP.COM
// keytab 생성
kadmin: xst -k zookeeper.keytab zookeeper/vm111@KOCAP.COM

kadmin: quit
```

- keytab 설정
```
cp zookeeper.keytab /home/fbpuser/zookeeper-3.4.6/conf/
chmod 400 /home/fbpuser/zookeeper-3.4.6/conf/zookeeper.keytab
chown fbpuser:fbpgroup /home/fbpuser/zookeeper-3.4.6/conf/zookeeper.keytab
```

- su fbpuser
- source ~/.bash_profile
``` 
vi ${ZOOKEEPER_HOME}/conf/zoo.cfg
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
jaasLoginRenew=3600000


vi ${ZOOKEEPER_HOME}/conf/jaas.conf
Server {
  com.sun.security.auth.module.Krb5LoginModule required
  useKeyTab=true
  keyTab="/home/fbpuser/zookeeper-3.4.6/conf/zookeeper.keytab"
  storeKey=true
  useTicketCache=false
  principal="zookeeper/vm111@KOCAP.COM";
};

vi ${ZOOKEEPER_HOME}/conf/java.env
export JVMFLAGS="-Djava.security.auth.login.config=/home/fbpuser/zookeeper-3.4.6/conf/jaas.conf"
```

- vm112와 vm211에도 동일하게 설정


## Zookeeper 클라이언트 설정
- principal, keytab
```
[root@vm111]# kadmin  -p admin/admin
// principal 추가
kadmin: addprinc -randkey zkcli@KOCAP.COM
// keytab 생성
kadmin: xst -k zkcli.keytab zkcli@KOCAP.COM
kadmin: quit
```


- keytab 설정
```
// zkcli.keytab 파일 이동
[root@vm111]# cp zkcli.keytab /home/fbpuser/zookeeper-3.4.6/conf/

// 읽기 전용 권한조정
[root@vm111]# chmod 400 /home/fbpuser/zookeeper-3.4.6/conf/zkcli.keytab
[root@vm111]# chown fbpuser:fbpgroup /home/fbpuser/zookeeper-3.4.6/conf/zkcli.keytab
```

- jaas.conf 파일에 Client 설정 추가
```
vi ${ZOOKEEPER_HOME}/conf/jaas.conf
Client {
  com.sun.security.auth.module.Krb5LoginModule required
  useKeyTab=true
  keyTab="/home/fbpuser/zookeeper-3.4.6/conf/zkcli.keytab"
  storeKey=true
  useTicketCache=false
  principal="zkcli@KOCAP.COM";
};

scp ${ZOOKEEPER_HOME}/conf/zkcli.keytab vm112:${ZOOKEEPER_HOME}/conf
scp ${ZOOKEEPER_HOME}/conf/zkcli.keytab vm211:${ZOOKEEPER_HOME}/conf

// ## vm112와 vm211에도 Client 설정 추가
```

## 확인
- 전체 Zookeeper 재시작
```
${ZOOKEEPER_HOME}/bin/zkServer.sh restart

// 접속 
[root@server01]# ${ZOOKEEPER_HOME}/bin/zkCli.sh -server vm111:2181

// zookeeper.out 파일에 보면 아래와 같은 인증관련 로그 확인 가능
2015-04-20 15:25:07,908 [myid:1] - INFO  [NIOServerCxn.Factory:0.0.0.0/0.0.0.0:2181:SaslServerCallbackHandler@118] - Successfully authenticated client: authenticationID=zkcli@KOCAP.COM;  authorizationID=zkcli@KOCAP.COM.
2015-04-20 15:25:07,917 [myid:1] - INFO  [NIOServerCxn.Factory:0.0.0.0/0.0.0.0:2181:SaslServerCallbackHandler@134] - Setting authorizedID: zkcli@KOCAP.COM
2015-04-20 15:25:07,917 [myid:1] - INFO  [NIOServerCxn.Factory:0.0.0.0/0.0.0.0:2181:ZooKeeperServer@964] - adding SASL authorization for authorizationID: zkcli@KOCAP.COM
```

