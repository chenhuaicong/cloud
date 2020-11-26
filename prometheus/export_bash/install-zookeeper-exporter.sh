#!/bin/bash

ipaddr=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
port="9381"
installdir="/data/zookeeper-exporter"
environment=$(hostname|awk -F '-' '{print $3}')
project=$(hostname|awk -F '-' '{print $2}')


if [[ $1 == "in" ]];then
cat >/lib/systemd/system/zookeeper-exporter.service<<eof
[Unit]
Description=zookeeper-exporter
After=network.target
[Service]
Type=simple
User=named
Group=named
ExecStart=${installdir}/zookeeper-exporter  -bind-addr ${ipaddr}:${port} -zookeeper ${ipaddr}:2181
Restart=on-failure
#ExecStop=
Restart=always
[Install]
WantedBy=multi-user.target
eof

	if [[ ! -d $installdir ]]; then
        	mkdir  $installdir
	fi

cd  ${installdir}/ && wget http://soft.kyepm.com/prometheus/zookeeper-exporter
chmod 755 ${installdir}/zookeeper-exporter

systemctl daemon-reload
systemctl start zookeeper-exporter.service
systemctl enable zookeeper-exporter.service

cat >${installdir}/zc.json<<eof
{
"id": "$(hostname)-${ipaddr}-zookeeper-exporter",
"name": "zookeeper-exporter",
"address": "${ipaddr}",
"port": ${port},
"meta":{
"environment":"${environment}",
"project":"${project}",
"service":"zookeeper",
"user":"$2"
},
"checks": [{
"http": "http://${ipaddr}:${port}/metrics",
"interval": "5s",
"timeout" : "20s"
}]
}
eof

	curl --request PUT --data   @${installdir}/zc.json    http://consul.ky-tech.com.cn/v1/agent/service/register?replace-existing-checks=1

elif [[ $1 == "out" ]];then
	systemctl stop zookeeper-exporter.service
	systemctl disable zookeeper-exporter.service 
#	rm -f ${installdir}/zookeeper-exporter*
#	rm -f ${installdir}/zc.json
#	rm -f /lib/systemd/system/zookeeper-exporter.service
	curl --request PUT  http://consul.ky-tech.com.cn/v1/agent/service/deregister/$(hostname)-${ipaddr}-zookeeper-exporter
else
	echo "参数1为in代表注册，为out代表下线"
fi

