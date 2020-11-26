#!/usr/bin/env bash

#当前版本 	1.2.0
#部署路径 	/usr/local/prometheus/elasticsearch_exporter
#配置目录 	/usr/local/prometheus/elasticsearch_exporter
#启停方式 	systemctl [start|stop|restart|status] elasticsearch_exporter
#端口 	9108
#运行用户   app
# https://github.com/justwatchcom/elasticsearch_exporter
# scripts by lrx 2020/5/23 v1.0.0

root_path='/usr/local/prometheus'
install_path="${root_path}/elasticsearch_exporter"

name='elasticsearch_exporter'
exporter_type="${name%_exporter}"
port='9108'
server_hostname=$(hostname)

ShowUsage() {
    echo "Usage: $0 es_host:port such as: $0 127.0.0.1:9092"
    exit 1
}

if [[ $# -lt 1 ]]; then ShowUsage; fi

# 构造启动配置参数
es_server="${1}"
es_server_url="http://${es_server}"

# 询问ES是否需要认证
read -r -p "ES是否有密码 yes/no?" answer
if [[ ${answer} =~ ^y(es)?$ ]]; then
    read -r -p "请输入ES帐号?" es_id
    read -r -p "请输入ES密码?" es_pw
    if [[ ! -n ${es_id} ]]; then
        echo -e "\n没有输入ES帐号，程序退出，请重新运行安装脚本"
        exit 1
    fi
    if [[ ! -n ${es_pw} ]]; then
        echo -e "\n没有输入ES密码，程序退出，请重新运行安装脚本"
        exit 1
    fi
    es_server_url="http://${es_id}:${es_pw}@${es_server}"
fi

if [[ ! -d ${root_path} ]]; then
    mkdir -p ${root_path}
fi

if [[ -d ${install_path} ]]; then
    mv ${install_path} ${install_path}_bak_$(date '+%Y-%m-%d_%H_%M_%S')
fi
cd /opt/
wget http://soft.kyepm.com/prometheus/elasticsearch_exporter-1.1.0.linux-amd64.tar.gz
if [[ $? -ne 0 ]];then
    echo "download fail,please"
    exit 1
fi
tar zxf elasticsearch_exporter-1.1.0.linux-amd64.tar.gz
mv elasticsearch_exporter-1.1.0.linux-amd64 ${install_path}
rm -vf elasticsearch_exporter-1.1.0.linux-amd64.tar.gz

chown -R app.app ${install_path}
chmod +x ${install_path}/elasticsearch_exporter

cat >/usr/lib/systemd/system/elasticsearch_exporter.service<<eof
[Unit]
Description=elasticsearch_exporter
Documentation=https://github.com/justwatchcom/elasticsearch_exporter
After=network.target

[Service]
Type=simple
User=app
ExecStart=${install_path}/elasticsearch_exporter --web.listen-address=0.0.0.0:9108 --es.uri=${es_server_url}
Restart=on-failure
[Install]
WantedBy=multi-user.target
eof

systemctl daemon-reload
systemctl enable elasticsearch_exporter
systemctl restart elasticsearch_exporter
sleep 1
systemctl status elasticsearch_exporter

if [[ $? -eq 0 ]];then
    echo "elasticsearch_exporter Successful installation"
else
    echo "elasticsearch_exporter Installation failed, please check"
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
"http://consul.ky-tech.com.cn/v1/agent/service/register?replace-existing-checks=1"

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