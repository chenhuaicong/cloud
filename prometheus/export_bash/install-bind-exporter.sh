#!/bin/bash

ipaddr=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
port="9123"
installdir="/data/bindexporter/"
environment=$(hostname|awk -F '-' '{print $3}')
project=$(hostname|awk -F '-' '{print $2}')


if [[ $1 == "in" ]];then
cat >/lib/systemd/system/bind-exporter.service<<eof
[Unit]
Description=bindexporter
After=network.target
[Service]
Type=simple
User=named
Group=named
ExecStart=/data/bindexporter/bind-exporter   --web.listen-address=$ipaddr:$port   --bind.stats-url=http://127.0.0.1:8053/  -web.telemetry-path=/metrics   -bind.pid-file=/run/named/named.pid
Restart=on-failure
#ExecStop=
Restart=always
[Install]
WantedBy=multi-user.target
eof

	if [[ ! -d $installdir ]]; then
        	mkdir  $installdir
	fi

	cd  ${installdir} && wget http://soft.example.com/prometheus/bind-exporter
	chown -R  named:named  ${installdir}bind-exporter
	chmod u+x ${installdir}bind-exporter

	systemctl daemon-reload
	systemctl start bind-exporter.service
	systemctl enable bind-exporter.service

cat >${installdir}zc.json<<eof
{
"id": "$(hostname)-${ipaddr}-bindexporter",
"name": "bind-exporter",
"address": "${ipaddr}",
"port": ${port},
"meta":{
"environment":"${environment}",
"project":"${project}",
"service":"dns",
"user":"161902"
},
"checks": [{
"http": "http://${ipaddr}:${port}/metrics",
"interval": "5s",
"timeout" : "20s"
}]
}
eof

	curl --request PUT --data   @${installdir}zc.json    http://consul.example.com.cn/v1/agent/service/register?replace-existing-checks=1

elif [[ $1 == "out" ]];then
#	systemctl stop bind-exporter.service
#	systemctl disable bind-exporter.service 
#	rm -f ${installdir}bind-exporter
#	rm -f ${installdir}zc.json
#	rm -f /lib/systemd/system/bind-exporter.service
	curl --request PUT  http://consul.example.com.cn/v1/agent/service/deregister/$(hostname)-${ipaddr}-bindexporter
else
	echo "参数1为in代表注册，为out代表下线"
fi

