#!/bin/bash

ipaddr=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
port="9102"
installdir="/data/process/"
environment=$(hostname|awk -F '-' '{print $3}')
project=$(hostname|awk -F '-' '{print $2}')


if [[ $1 == "in" ]];then
cat >/lib/systemd/system/process-exporter.service<<eof
[Unit]
Description=jcexport
After=network.target
[Service]
ExecStart=/data/process/process-exporter  -web.listen-address   $ipaddr:$port   -config.path  /data/process/conf.yml
Restart=on-failure
#ExecStop=
Restart=always
[Install]
WantedBy=multi-user.target
eof

	if [[ ! -d $installdir ]]; then
        	mkdir  $installdir
	fi

cat >${installdir}conf.yml<<eof
process_names:
  - name: "{{.Comm}}"
    cmdline:
    - '.+'
eof


	cd  ${installdir} && wget http://soft.example.com/prometheus/process-exporter
	chmod 755 ${installdir}process-exporter

	systemctl daemon-reload
	systemctl start process-exporter.service
	systemctl enable process-exporter.service

cat >${installdir}zc.json<<eof
{
"id": "$(hostname)-${ipaddr}-process",
"name": "process-exporter",
"address": "${ipaddr}",
"port": ${port},
"meta":{
"environment":"${environment}",
"project":"${project}",
"service":"process",
"user":"161902"
},
"checks": [{
"http": "http://${ipaddr}:${port}/metrics",
"interval": "5s"
}]
}
eof

	curl --request PUT --data   @${installdir}zc.json    http://consul.example.com.cn/v1/agent/service/register?replace-existing-checks=1

elif [[ $1 == "out" ]];then
	systemctl stop process-exporter.service
#	systemctl disable process-exporter.service 
#	rm -f ${installdir}process-exporter
#	rm -f ${installdir}conf.yml
#	rm -f ${installdir}zc.json
#	rm -f /lib/systemd/system/process-exporter.service
	curl --request PUT  http://consul.example.com.cn/v1/agent/service/deregister/$(hostname)-${ipaddr}-process
else
	echo "参数1为in代表注册，为out代表下线"
fi

