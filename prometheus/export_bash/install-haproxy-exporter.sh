#!/bin/bash

#注册：./install-haproxy-exporter.sh in www.baidu.com  "小明工号,小红工号"
#下线：./install-haproxy-exporter.sh out

ipaddr=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
port="9101"
installdir="/data/haproxy-exporter"
environment=$(hostname|awk -F '-' '{print $3}')
project=$(hostname|awk -F '-' '{print $2}')
service=$(hostname|awk -F '-' '{print $4}')

if [[ $1 == "in" ]];then

        if [[ ! -d $installdir ]]; then
                mkdir  $installdir
        fi

source /etc/profile
cat /etc/haproxy/haproxy.cfg |grep 'listen admin_stats' >/dev/null
        if [ "$?" -ne 0 ];then
		echo "haproxy的配置需要增加以下配置项"
		echo '
listen admin_stats
    bind *:33333
    mode http
    maxconn 10
    stats refresh 10s
    stats uri /haproxy
    stats realm Haproxy
    stats hide-version
'
                exit  10
        fi
cat >/lib/systemd/system/haproxy-exporter.service<<eof
[Unit]
Description=haproxy-exporter
After=network.target
[Service]
ExecStart=$installdir/haproxy-exporter   --haproxy.scrape-uri=http://${ipaddr}:33333/haproxy?stats;csv
Restart=on-failure
#ExecStop=
Restart=always
[Install]
WantedBy=multi-user.target

eof

        cd  ${installdir} && wget http://soft.example.com/prometheus/haproxy-exporter
        chmod u+x ${installdir}/haproxy-exporter

        systemctl daemon-reload
        systemctl start haproxy-exporter.service
        systemctl enable haproxy-exporter.service
cat >${installdir}/zc.json<<eof
{
"id": "$(hostname)-${ipaddr}-haproxy-exporter",
"name": "haproxy-exporter",
"address": "${ipaddr}",
"port": ${port},
"meta":{
"environment":"${environment}",
"project":"${project}",
"service":"${service}",
"user":"$2"
},
"checks": [{
"http": "http://${ipaddr}:${port}/metrics",
"interval": "5s",
"timeout" : "10s"
}]
}
eof

        curl --request PUT --data   @${installdir}/zc.json    http://consul.example.com.cn/v1/agent/service/register?replace-existing-checks=1

elif [[ $1 == "out" ]];then
        systemctl stop haproxy-exporter.service
#        systemctl disable haproxy-exporter.service
#        rm -f ${installdir}/haproxy-exporter
#        rm -f ${installdir}/zc.json
#        rm -f /lib/systemd/system/haproxy-exporter.service
        curl --request PUT  http://consul.example.com.cn/v1/agent/service/deregister/$(hostname)-${ipaddr}-haproxy-exporter
else
        echo "参数1为in代表注册，为out代表下线"
fi

