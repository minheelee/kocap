
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
