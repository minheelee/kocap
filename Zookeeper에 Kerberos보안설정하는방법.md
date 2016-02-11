
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

