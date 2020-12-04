FROM registry-dev.example.com/base/centos:7.6-1810


# 维护者信息

MAINTAINER chenhuaicong


#执行命令：创建目录

RUN mkdir -p /opt


#将jdk1.8.0_191添加到镜像centos的/opt/目录下，并命名为jdk

ADD jdk1.8.0_131 /opt/jdk


#将apache-tomcat-8.5.14添加到镜像centos的/usr/local/soft/目录下，并命名为tomcat

ADD apache-tomcat-9.0.34 /opt/tomcat


#添加环境变量

ENV JAVA_HOME /opt/jdk

ENV CATALINA_HOME /opt/tomcat

ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/bin


#暴露8080端口

EXPOSE 8080


#启动时运行tomcat

CMD ["/opt/tomcat/bin/catalina.sh","run"]
