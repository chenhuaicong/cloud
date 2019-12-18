#!/bin/bash -xe
namespace=$1
app_name=$2
num=0
imagepullfail=0

oc get deploymentconfig ${app_name} -n ${namespace} >> /dev/null 2>&1 && dc_status=true
if [ "${dc_status}"x != "true"x ];then
    echo "deploymentconfig not found,please check !!!"
    exit 1
fi


update_version=`oc  rollout history deploymentconfig ${app_name} -n ${namespace}|grep -v  ^$|awk 'END  {print $1}'`
echo  "${app_name}版本更新成功，请等待程序启动，可跳转至容器云平台(https://docker-dev.ky-tech.com.cn/console/project/${namespace}/browse/rc/${app_name}-${update_version}?tab=details)查看启动情况"
echo -n "程序启动中. "
while true
do
    let num++
    if [ ${num} -gt 250 ];then
	echo "发布超时,请检查..或者到容器云平台查看详情;https://docker-dev.ky-tech.com.cn/console/project/${namespace}/browse/rc/${app_name}-${update_version}?tab=details"
	exit 1
    fi

    oc  get pod -l run=${app_name} -n ${namespace} |grep ImagePullBackOff  >> /dev/null 2>&1  && let imagepullfail++
    if [ ${imagepullfail} -gt 10 ];then
        echo "${app_name} 镜像拉取失败, 请检测${app_name}是否在联调环境构建,或者到容器云平台查看详情;https://docker-dev.ky-tech.com.cn/console/project/${namespace}/browse/rc/${app_name}-${update_version}?tab=details"
        exit 1
    fi   
 
    #oc  get pod -l run=${app_name} -n ${namespace} > ./pod_list.txt
    #oc  get pod -l run=${app_name}|awk 'END  {print $2}'
    update_status=`oc  rollout history deploymentconfig ${app_name} -n ${namespace}|grep -v  ^$|awk 'END  {print $2}'`
    if [ "${update_status}"x = "Running"x ];then
        echo -n "."
        sleep 2
    elif [ "${update_status}"x = "Complete"x ];then
	echo ""
        echo "${app_name} 更新成功!"
        break
    elif [ "${update_status}"x = "Failed"x ];then
#        if [ "${pod_status}"x = "ImagePullBackOff"x ];then
#            echo ""
#            echo "${app_name} 镜像拉取失败, 请检测${app_name}是否在联调环境构建"
#        fi
	echo ""
        echo "${app_name} 更新失败，请检查 !"
        exit 1
    fi
done
