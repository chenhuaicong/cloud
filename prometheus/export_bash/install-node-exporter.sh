#!/bin/bash
#运行用户   app

ipaddr=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
port="9100"
installdir="/data/node-exporter"
environment=$(hostname|awk -F '-' '{print $3}')

get_project() {
    # 1先从hostname获取，然后打印出来，让运维确认，如果不是，请手动输入
    # echo "project：值是vms/ims/oa/oem等的模块名字"
    hostname_project=$(hostname | awk -F"-" '{print $2}')
    read -r -p "请确认项目为是否为:${hostname_project} yes/no?" answer
    if [[ ${answer} =~ ^y(es)?$ ]]; then
        hostname_project=${hostname_project}
    else
        read -r -p "请输入项目名,如:erp-tms/vms/ims/oa/oem等的模块名字:" project_name
        if [[ ! -n ${project_name} ]]; then
            echo -e "\n没有输入项目名，程序退出，请重新运行安装脚本"
            exit 1
        fi
        project=${project_name}
    fi
}

get_project

if [[ $1 == "in" ]];then
cat >/lib/systemd/system/node-exporter.service<<eof
[Unit]
Description=node-exporter
After=network.target
[Service]
Type=simple
User=app
Group=app
ExecStart=${installdir}/node-exporter
Restart=on-failure
#ExecStop=
Restart=always
[Install]
WantedBy=multi-user.target
eof

if [[ ! -d $installdir ]]; then
	mkdir  $installdir
fi

cd  ${installdir}/ && wget http://soft.example.com/prometheus/node-exporter
chmod 755 ${installdir}/node-exporter

systemctl daemon-reload
systemctl start node-exporter.service
systemctl enable node-exporter.service

systemctl status node-exporter.service

cat >${installdir}/zc.json<<eof
{
"id": "$(hostname)-${ipaddr}-node-exporter",
"name": "node-exporter",
"address": "${ipaddr}",
"port": ${port},
"meta":{
"environment":"${environment}",
"project":"${project}",
"service":"node",
"user":"$2"
},
"checks": [{
"http": "http://${ipaddr}:${port}/metrics",
"interval": "5s",
"timeout" : "20s"
}]
}
eof

curl --request PUT --data   @${installdir}/zc.json    http://consul.example.com.cn/v1/agent/service/register?replace-existing-checks=1

echo "node-exporter已成功运行，已注册到consul"

elif [[ $1 == "out" ]];then
	systemctl stop node-exporter.service
	systemctl disable node-exporter.service 
#	rm -f ${installdir}/node-exporter*
#	rm -f ${installdir}/zc.json
#	rm -f /lib/systemd/system/node-exporter.service
	curl --request PUT  http://consul.example.com.cn/v1/agent/service/deregister/$(hostname)-${ipaddr}-node-exporter
else
	echo "参数1为in代表注册，为out代表下线"
fi
