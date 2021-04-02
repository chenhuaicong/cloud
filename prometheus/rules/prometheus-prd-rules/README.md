# prometheus (普罗米修斯) 告警策略配置文件
## 策略文件规范
1. 文件名后缀使用 .yml
1. 文件名命名规范： 项目名_环境_监控组件名.yml 比如： tms_prod_rabbitmq.yml
1. 可使用多个文件细化告警项
1. 存放目录按各个 exoport 目录存放

## 告警信息发送方式
将会通过邮件及跨声发送

## 本git库提交后会自动同步到prometheus服务器，并自动加载