
# Zookeeper에 Kerberos보안설정하는방법
- 사전 작업
    - centos6에 [Kerberos보안설정.md](Kerberos보안설정.md)
    - centos6에 [hadoop2.4설치및HA구성.md](hadoop2.4설치및HA구성.md) 에서 zookeeper 설치 참조

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