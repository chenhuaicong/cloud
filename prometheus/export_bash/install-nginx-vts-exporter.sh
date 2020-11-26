#!/bin/bash

ipaddr=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
port="9913"
installdir="/data/nginx-exporter"
environment=$(hostname|awk -F '-' '{print $3}')
project=$(hostname|awk -F '-' '{print $2}')
service=$(hostname|awk -F '-' '{print $4}')

if [[ $1 == "in" ]];then

        if [[ ! -d $installdir ]]; then
                mkdir  $installdir
        fi

source /etc/profile
/usr/local/nginx/sbin/nginx -V &> ${installdir}/nginx-V
cat ${installdir}/nginx-V|grep "nginx-module-vts" >/dev/null
        if [ "$?" -ne 0 ];then
                echo 'nginx-module-vts 模块不存在，请重新编译nginx添加nginx-module-vts模块'
                echo "下载地址：http://soft.kyepm.com/prometheus/nginx-module-vts.tar"
                exit  10
        fi

cat >/usr/local/nginx/conf/vhost/nginx-exporter.conf <<eof
server {
        listen          80;
        server_name     ${ipaddr};

        vhost_traffic_status on;
        location /status {
                vhost_traffic_status_display;
                vhost_traffic_status_display_format html;
        }
}

eof

cat >/lib/systemd/system/nginx-exporter.service<<eof
[Unit]
Description=nginxexporter
After=network.target
[Service]
ExecStart=${installdir}/nginx-exporter -nginx.scrape_uri=http://${ipaddr}/status/format/json
Restart=on-failure
#ExecStop=
Restart=always
[Install]
WantedBy=multi-user.target

eof

        cd  ${installdir} && wget http://soft.kyepm.com/prometheus/nginx-exporter
        chmod u+x ${installdir}/nginx-exporter

        systemctl daemon-reload
        systemctl start nginx-exporter.service
        systemctl enable nginx-exporter.service
cat >${installdir}/zc.json<<eof
{
"id": "$(hostname)-${ipaddr}-nginxexporter",
"name": "nginx-exporter",
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

        curl --request PUT --data   @${installdir}/zc.json    http://consul.ky-tech.com.cn/v1/agent/service/register?replace-existing-checks=1

echo '

#####################################################
模块安装完后需要在nginx.conf的http{}里增加如下配置：#
  vhost_traffic_status_zone;                        #
  vhost_traffic_status_filter_by_host on;           #
然后reload   nginx                                  #
#####################################################
'


elif [[ $1 == "out" ]];then
        systemctl stop nginx-exporter.service
#        systemctl disable nginx-exporter.service
#        rm -f ${installdir}/nginx-exporter
#        rm -f ${installdir}/zc.json
#        rm -f ${installdir}/nginx-V
#        rm -f /lib/systemd/system/nginx-exporter.service
#       rm -f /data/1180nginx/vhost/nginx-exporter.conf
        curl --request PUT  http://consul.ky-tech.com.cn/v1/agent/service/deregister/$(hostname)-${ipaddr}-nginxexporter
else
        echo "参数1为in代表注册，为out代表下线"
fi


