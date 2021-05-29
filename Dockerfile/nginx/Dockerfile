#第一行先定义基础镜像,表示当前镜像文件是基于哪个进行编辑的.
FROM harbor.ky-tech.com.cn/library/centos:7.6-1810

#指定镜像维护者的信息.
MAINTAINER chenhuaicong 

ENV nginxVersion="nginx-1.16.1"

#除了安装编译nginx的依赖的安装包外,还可以将一些常用的命令工具也安装上
RUN yum -y install epel-release && yum -y install wget vim net-tools bridge-utils firewalld bc iotop bc gcc gcc-c++ glibc glibc-devel pcre pcre-devel openssl openssl-devel zip unzip zlib-devel lrzsz tree ntpdate telnet lsof tcpdump wget libevent libevent-devel systemd-devel bash-completion traceroute psmisc 



#下载解压&&编译安装nginx
RUN  wget -P /usr/local/src/ http://soft.kyepm.com/nginx/$nginxVersion.tar.gz  \
&& tar -xf /usr/local/src/$nginxVersion.tar.gz -C /usr/local/src/ \
&& sed -i "s#nginx/#WebServer/#g" /usr/local/src/$nginxVersion/src/core/nginx.h \
&& sed -i "s#>nginx<#>WebServer<#g" /usr/local/src/$nginxVersion/src/http/ngx_http_special_response.c \
&& sed -i "s#Server: nginx#Server: WebServer#g" /usr/local/src/$nginxVersion/src/http/ngx_http_header_filter_module.c \
&& cd /usr/local/src/$nginxVersion \
&& ./configure \
--prefix=/usr/local/nginx \
--user=nginx --group=nginx \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_stub_status_module \
--with-http_gzip_static_module \
--with-pcre --with-stream \
--with-stream_ssl_module \
--with-stream_realip_module \
&& make && make install \
&& ln -sv /usr/local/nginx/sbin/nginx /usr/sbin/nginx \
&& mkdir -p /usr/local/nginx/conf/vhost/ \
&& mkdir -p /data/logs/nginx/ 

#将nginx的配置文件放在镜像的指定编译安装的目录
COPY nginx.conf /usr/local/nginx/conf/
COPY default.conf /usr/local/nginx/conf/vhost/

#创建nginx用户,yum方式安装无需做此步骤，因为默认yum安装会自动创建nginx用户,咱们上面指令了以nginx用户运行,因此我们需要在镜像中创建"nginx用户"
RUN useradd nginx -s /sbin/nologin -u 2000

#定义向外暴露的端口号,多个端口用空格做间隔,启动容器的时候"-p"需要使用此端向外端映射.
EXPOSE 80/tcp 443/tcp

#定义前台运行的命令,每个Docker只能有一条，如果定义了多条"CMD"指令那么最后一条CMD指令会覆盖之前的(即只有最后一条CMD被执行).

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]