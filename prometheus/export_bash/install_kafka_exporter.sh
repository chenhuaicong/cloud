#!/usr/bin/env bash

#当前版本 	1.2.0
#部署路径 	/usr/local/prometheus/kafka_exporter
#配置目录 	/usr/local/prometheus/kafka_exporter
#启停方式 	systemctl [start|stop|restart|status] kafka_exporter
#端口 	9308
#运行用户   app
# https://github.com/danielqsj/kafka_exporter
# scripts by lrx 2020/5/7 v1.0.0

root_path='/usr/local/prometheus'
install_path="${root_path}/kafka_exporter"

name='kafka_exporter'
exporter_type="${name%_exporter}"
port='9308'
server_hostname=$(hostname)

ShowUsage() {
    echo "Usage: $0 kafka_host:port [another-server ...] such as: $0 10.121.39.1:9092 10.121.39.2:9092"
    exit 1
}

if [[ $# -lt 1 ]]; then ShowUsage; fi

# 构造启动配置参数
kafka_server_conf=""
for i in $@
do
    kafka_server_conf=" $kafka_server_conf --kafka.server=$i"
done
echo ${kafka_server_conf}

if [[ ! -d ${root_path} ]]; then
    mkdir -p ${root_path}
fi

if [[ -d ${install_path} ]]; then
    mv ${install_path} ${install_path}_bak_$(date '+%Y-%m-%d_%H_%M_%S')
fi
cd /opt/
wget http://soft.example.com/prometheus/kafka_exporter-1.2.0.linux-amd64.tar.gz
if [[ $? -ne 0 ]];then
    echo "download fail,please"
    exit 1
fi
tar zxf kafka_exporter-1.2.0.linux-amd64.tar.gz
mv kafka_exporter-1.2.0.linux-amd64 ${install_path}
rm -vf kafka_exporter-1.2.0.linux-amd64.tar.gz

chown -R app.app ${install_path}
chmod +x ${install_path}/kafka_exporter

cat >/usr/lib/systemd/system/kafka_exporter.service<<eof
[Unit]
Description=node_export
Documentation=https://github.com/prometheus/kafka_exporter
After=network.target

[Service]
Type=simple
User=app
ExecStart=${install_path}/kafka_exporter ${kafka_server_conf}  --topic.filter=^[A-Za-z0-9].*
Restart=on-failure
[Install]
WantedBy=multi-user.target
eof

systemctl daemon-reload
systemctl enable kafka_exporter
systemctl restart kafka_exporter
sleep 1
systemctl status kafka_exporter

if [[ $? -eq 0 ]];then
    echo "kafka_exporter Successful installation"
else
    echo "kafka_exporter Installation failed, please check"
fi

#rm -fv install_kafka_exporter.sh


# step 2 配置prometheus

#  - job_name: kafka_exporter
#    metrics_path: /metrics
#    scheme: http
#    static_configs:
#    - targets: ['10.121.39.1:9308']
#      labels:
#      instance: kafka_str

# step 3 导入 json 面板到 grafana

# 下载地址：https://grafana.com/grafana/dashboards/7589

# kafka-exporter-overview_rev5.json


get_local_ip() {
    #获取本地ip地址
    my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
    my_interface=$(ip route get 8.8.8.8 | awk -F"dev " 'NR==1{split($2,a," ");print a[1]}')
    server_ip=$(ifconfig ${my_interface} | grep -v 'inet6' | grep inet|awk '{print $2}')
    # 对比my_ip 和 server_ip 是否一样，一样就赋值给 server_ip
    if [[ "${my_ip}" == "${server_ip}" ]]; then
        if [[ -n ${server_ip} ]]; then
            server_ip=${server_ip}
        else
            echo "$(current_time) The server_ip get error,null,please check!"
            exit 1
        fi
    else
        echo "$(current_time) The server_ip get error,please check!"
        exit 1
    fi
}

get_local_ip
if [[ ! -z ${server_ip} ]]; then
    address=${server_ip}
fi

generate_id() {
    #id：用主机名+ip+类型；
    reg_id="${server_hostname}-${address}-${exporter_type}"
}

get_environment() {
# 生产环境
prd_str='prd|prod|produce'
# dev环境
dev_str='dev|develop'
# stg环境
stg_str='stg'
# str环境
str_str='str'
# uat环境
uat_str='uat|preprod'
# sit/test环境
tst_str='sit|tst|test'

if [[ $(echo ${server_hostname} | grep -E "${prd_str}" | wc -l) -eq 1 ]]; then
    environment="prod"
elif [[ $(echo ${server_hostname} | grep -E "${dev_str}" | wc -l) -eq 1 ]]; then
    environment="dev"
elif [[ $(echo ${server_hostname} | grep -E "${stg_str}" | wc -l) -eq 1 ]]; then
    environment="stg"
elif [[ $(echo ${server_hostname} | grep -E "${str_str}" | wc -l) -eq 1 ]]; then
    environment="str"
elif [[ $(echo ${server_hostname} | grep -E "${uat_str}" | wc -l) -eq 1 ]]; then
    environment="uat"
elif [[ $(echo ${server_hostname} | grep -E "${tst_str}" | wc -l) -eq 1 ]]; then
    environment="test"
else
    echo "不能判断环境，请手动注册"
    read -r -p "请输入环境" environment
    if [[ ! -n ${environment} ]]; then
        echo -e "\n输入环境为空! exit"
        exit 1
    fi
fi
}

get_project() {
    # 1先从hostname获取，然后打印出来，让运维确认，如果不是，请手动输入
    # echo "project：值是vms/ims/oa/oem等的模块名字"
    hostname_project=$(echo ${server_hostname} | awk -F"-" '{print $2}')
    echo "请确认项目为是否为:${hostname_project} Y/N?"
    read -r -p "请确认项目为是否为:${hostname_project} yes/no?" answer
    if [[ ${answer} =~ ^y(es)?$ ]]; then
        hostname_project=${hostname_project}
    else
        echo "请输入项目名：值是vms/ims/oa/oem等的模块名字"
        read -r -p "请输入项目名：值是vms/ims/oa/oem等的模块名字:" project_name
        if [[ ! -n ${project_name} ]]; then
            echo -e "\n没有输入项目名，程序退出，请重新运行安装脚本"
            exit 1
        fi
        hostname_project=${project_name}
    fi
}

get_user_id() {
    #输入运维工号，多个写在一个字符串里用英文逗号隔开，用来发告警的
    echo "输入运维工号，多个写在一个字符串里用英文逗号隔开，用与后期发送告警"
    read -r user_id
    if [[ ! -n ${user_id} ]]; then
        echo -e "\n没有输入工号，程序退出，请重新运行安装脚本"
        exit 1
    else
        echo "输入工号为:${user_id}"
    fi
}

register_to_consul() {
#生成 json 文件
cat >/tmp/register.json<<eof
{
"id": "${reg_id}",
"name": "${name}",
"address": "${address}",
"port": ${port},
"meta":{
"environment":"${environment}",
"project":"${hostname_project}",
"service":"${exporter_type}",
"user":"${user_id}"
},
"checks": [{
"http": "${http_url}",
"interval": "5s"
}]
}
eof

curl -X PUT -d @/tmp/register.json \
"http://consul.example.com.cn/v1/agent/service/register?replace-existing-checks=1"

}

# 注册服务
register() {
    #1 get_id
    generate_id
    name="${exporter_type}-exporter"
    # get_environment
    get_environment
    # project 项目名
    get_project
    # user_id
    get_user_id
    http_url="http://${address}:${port}/metrics"
    register_to_consul

}

register