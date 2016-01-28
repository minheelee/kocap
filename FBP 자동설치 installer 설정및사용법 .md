
# FBP 자동설치 installer 설정 및 사용법 


## 1.  준비
yum groupinstall -y “Development tools”
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel
yum install -y php  php-devel php-pear libssh2 libssh2-devel
yum install -y perl  
yum install -y php-sqlite*  
yum install -y php-mysql


tar xvf libssh2-1.6.0.tar.gz
cd libssh2-1.6.0 
./configure
make && make install


tar xvf ssh2-0.12.tgz
cd ssh2-0.12
phpize
./configure
make && make install


vi /etc/php.ini  # 아래  추가 
extension=ssh2.so

php -m | grep ssh2 # 확인
ssh2  

## 2. 사용법
svn co  svn://112.172.129.142/NGT/BigData/Sources/HadoopMonitoring/installer  --username  ID  --password 비번
cd installer 

rm -f fbpsetup.db
cp hadoop_nodes.txt hosts.txt
vi hosts.txt  # 하둡을 설치할 host들의 이름들을 기입

vi /etc/hosts # IP  hostname을 등록함. DNS 등록되어 있으면 생략함.

./fbp_install.sh  # 시작함. 








