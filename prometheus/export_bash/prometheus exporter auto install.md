
# prometheus exporter 自动安装脚本



> 运行脚本的时候需要填些相关的信息，如：工号、环境、项目，下面三个脚本安装完毕会自动注册到consul注册中心。

## kafka_exporter 安装脚本说明

### 安装方法：
 1、先整理好需要监控的kafka集群 ip:port  
 ```
比如 10.10.10.1:9092 10.10.·0.2:9092  10.10.10.3:9092
```
 2、下载安装脚本及运行

```
cd /opt/ && wget http://soft.example.com/prometheus/install_kafka_exporter.sh
执行脚本，并带上kafka ip及端口
bash install_kafka_exporter.sh
示例：
bash install_kafka_exporter.sh 10.10.10.1:9092 10.10.10.2:9092  10.10.10.3:9092
停止命令
systemctl stop kafka_exporter
启动命令
systemctl start kafka_exporter
重启命令
systemctl restart kafka_exporter
查看运行状态
systemctl status kafka_exporter
```

## install_rabbitmq_exporter.sh 使用方法

### 安装方法：
1、前提条件 RabbitMQ 需要安装 management_plugin ，并配置好帐号密码

2、整理好 management_plugin 地址及帐号信息：需要  management_plugin 地址  用户密码  密码


3、下载安装脚本及执行
```
cd /opt/ && wget http://soft.example.com/prometheus/install_rabbitmq_exporter.sh
执行脚本，并带上参数
bash install_rabbitmq_exporter.sh
示例
bash install_rabbitmq_exporter.sh http://127.0.0.1:15672 admin passwd


停止命令

systemctl stop rabbitmq_exporter

启动命令

systemctl start rabbitmq_exporter

重启命令

systemctl restart rabbitmq_exporter

查看运行状态

systemctl status rabbitmq_exporter
```

## install_redis_exporter.sh 使用方法

> 主要监控单个redis实例的运行情况，如需要监控redis 集群请查看 github 官方配置文档，或者 redis_exporter 下面的 RedME 文档
 
1、脚本需要准备好 redis实例ip端口及 密码

2、下载脚本及运行
```
cd /opt/ && wget http://soft.example.com/prometheus/install_redis_exporter.sh
执行安装脚本
bash install_redis_exporter.sh
示例：
bash install_redis_exporter.sh  127.0.0.1:6379 redispasswd


停止命令

systemctl stop redis_exporter

启动命令

systemctl start redis_exporter

重启命令

systemctl restart redis_exporter

查看运行状态

systemctl status redis_exporter
```