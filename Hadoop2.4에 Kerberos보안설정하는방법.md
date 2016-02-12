
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

# 이후 작업 ~~~~~~~~~~

