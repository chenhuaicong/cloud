#!/usr/bin/env bash
#当前版本 	1.6.0
#部署路径 	/usr/local/prometheus/redis_exporter
#配置目录 	/usr/local/prometheus/redis_exporter
#启停方式 	systemctl [start|stop|restart|status] redis_exporter
#端口 	9121
#运行用户   app
# https://github.com/oliver006/redis_exporter
# scripts by lrx 2020/5/8 v1.0.0

root_path='/usr/local/prometheus'
install_path="${root_path}/redis_exporter"

name='redis_exporter'
exporter_type="${name%_exporter}"
port='9121'
server_hostname=$(hostname)


ShowUsage() {
    echo "Usage: $0 redis_host:port such as: $0 127.0.0.1:6379"
    exit 1
}

if [[ $# -ne 1 ]]; then ShowUsage; fi
redis_host=$1

# 输入获得redis密码
read -r -s -p "input redis password:" redis_pw
if [[ ! -n ${redis_pw} ]]; then
    echo -e "\nyou have not input password! exit"
    exit 1
fi


if [[ ! -d ${root_path} ]]; then
    mkdir -p ${root_path}
fi

if [[ -d ${install_path} ]]; then
    mv ${install_path} ${install_path}_bak_$(date '+%Y-%m-%d_%H_%M_%S')
fi

cd /opt/
wget http://soft.kyepm.com/prometheus/redis_exporter-v1.6.0.linux-amd64.tar.gz
if [[ $? -ne 0 ]];then
    echo "download fail,please"
    exit 1
fi

tar zxf redis_exporter-v1.6.0.linux-amd64.tar.gz
mv redis_exporter-v1.6.0.linux-amd64 ${install_path}
#rm redis_exporter-v1.6.0.linux-amd64.tar.gz -vf

chown -R app.app ${install_path}
chmod +x ${install_path}/redis_exporter

cat >/usr/lib/systemd/system/redis_exporter.service<<eof
[Unit]
Description=redis_exporter
Documentation=https://github.com/oliver006/redis_exporter
After=network.target

[Service]
Type=simple
User=app
ExecStart=${install_path}/redis_exporter -redis.addr ${redis_host}  -redis.password ${redis_pw}
Restart=on-failure
[Install]
WantedBy=multi-user.target
eof

systemctl daemon-reload
systemctl enable redis_exporter
systemctl start redis_exporter
sleep 1
systemctl status redis_exporter
if [[ $? -eq 0 ]];then
    echo "redis_exporter Successful installation"
else
    echo "redis_exporter Installation failed, please check"
fi

# step 2 配置prometheus

#scrape_configs:
#  - job_name: redis_exporter
#    static_configs:
#    - targets: ['<<REDIS-EXPORTER-HOSTNAME>>:9121']

#在安装有exporter的节点上执行执行
#
#curl -X PUT -d '{"id": "szpbs-prometheus-prd-cluster01-10.120.35.60-node","name": "node-exporter","address": "10.120.35.60","port": 9100,"meta":{"environment":"produce","project":"monitor","service":"node","user":"工号,工号"},"checks": [{"http": "http://10.120.35.60:9100/metrics", "interval": "5s"}]}'  http://consul.ky-tech.com.cn/v1/agent/service/register
#
#数据结构解释：
#
#注意所有横线使用中划线，不使用下划线；
#
#id：用主机名+ip+类型；
#
#name：是exporter类型，值包括redis-exporter/rabbitmq-exporter/kafka-exporter/haproxy-exporter;
#
#address：是exporter所在主机的ip;
#
#port：是exporter的端口;
#
#meta：{"environment":"环境","project":"模块名字","service":"所监控服务类型","user":"工号，工号"}
#
#environment：值分别有produce/dev/test/pressure/uat；
#
#project：值是vms/ims/oa/oem等的模块名字；
#
#service：值是redis/rabbitmq/kafka/haproxy等；
#
#user：是维护人的工号，多个写在一个字符串里用英文逗号隔开，用来发告警的；
#
#checks：是exporter暴漏的metrics地址；
#
# http://consul.ky-tech.com.cn/v1/agent/service/register   ：是consul的api注册接口；

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