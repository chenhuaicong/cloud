#!/bin/bash
namespace=$1
app_name=$2

while true
do
    oc  get pod -l run=${app_name}
    o|awk 'END  {print $2}'c  get pod -l run=${app_name}|awk 'END  {print $2}'
    status=`oc  rollout history deploymentconfig ${app_name} -n ${namespace}|grep -v  ^$|awk 'END  {print $2}'`
    if [ "${status}"x = "Running"x ];then
   	echo "${app_name} is running,Please waiting ..."
    elif [ "${status}"x = "Complete"x ];then
   	echo "${app_name} rollingUpdate is success !"
    	break
    elif [ "${status}"x = "Failed"x ];then
   	echo "${app_name} rollingUpdate is Failed !\nPlease check !"
        break
    fi
    sleep 10
done
