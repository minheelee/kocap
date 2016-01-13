FROM centos:centos7

MAINTAINER minhee Lee <mhlee@feelingk.com>
#jdk 1.7.80
RUN yum -y install wget && \
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm && \
    echo "b516630a940d83b066cf1e6479ec59fe  jdk-7u80-linux-x64.rpm" >> MD5SUM && \
    md5sum -c MD5SUM && \
    rpm -Uvh jdk-7u80-linux-x64.rpm && \
    yum -y remove wget && \
    rm -f jdk-7u80-linux-x64.rpm MD5SUM
	
ENV JAVA_HOME=/usr/java/default
ENV PATH=$PATH:$JAVA_HOME/bin