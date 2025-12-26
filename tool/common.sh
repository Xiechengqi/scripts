#!/usr/bin/env bash

#
# xiechengqi
# 2021/08
# common shell functions and env
#

source /etc/profile

# println information
INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(TZ=UTC-8 date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
}

# println yellow color information
YELLOW() {
printf -- "\033[44;37m%s\033[0m " "[$(TZ=UTC-8 date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[33m%s\033[0m" "$1"
printf "\n"
}

# println error information
ERROR() {
printf -- "\033[41;37m%s\033[0m " "[$(TZ=UTC-8 date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
exit 1
}

# exec cmd and print error information
EXEC() {
local cmd="$1"
INFO "${cmd}"
eval ${cmd} 1> /dev/null
if [ $? -ne 0 ]; then
ERROR "Execution command (${cmd}) failed, please check it and try again."
fi
}

get_os() {
if [ -f "/etc/debian_version" ]; then
source /etc/os-release && local os="${ID}"
elif [ -f "/etc/fedora-release" ]; then
local os="fedora"
elif [ -f "/etc/redhat-release" ]; then
local os="centos"
else
exit 1
fi

if [ -f /etc/redhat-release ]; then
local os_full=`awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release`
elif [ -f /etc/os-release ]; then
local os_full=`awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release`
elif [ -f /etc/lsb-release ]; then
local os_full=`awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release`
else
exit 1
fi

local main_ver="$( echo $os_full | grep -oE  "[0-9.]+")"
printf -- "%s" "${os}${main_ver%%.*}"
}

OS() {
osType=$1
osVersion=$2
curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/os.sh | bash -s ${osType} ${osVersion} || exit 1
}

if_hyper_threading() {

physical_cpu_num=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
single_logical_cpu_num=$(cat /proc/cpuinfo | grep "cpu cores" | uniq | wc -l)
logical_cpu_num=$(expr ${physical_cpu_num} \* ${single_logical_cpu_num})
real_logical_cpu_num=$(cat /proc/cpuinfo | grep "processor" | wc -l)
[ "${real_logical_cpu_num}" -gt "${logical_cpu_num}" ] && echo "true" || echo "false"

}

check_if_in_china() {

if ! hash ping || ! hash curl
then
echo "Install ping and curl first please" && exit 1
fi
! ping -c 3 -W 3 1.1.1.1 &> /dev/null && ! ping -c 3 -W 3 baidu.com &> /dev/null && echo "Network exception, unable to connect to Ethernet !!!" && exit 1
check_location_api_arr=("3.0.3.0" "3.0.2.1" "3.0.2.9")
for check_location_api in ${check_location_api_arr[*]}
do
location=$(timeout 3 curl -SsL ${check_location_api} | grep location)
[ ".${location}" = "." ] && continue
echo "${location}" | grep '中国' &> /dev/null && echo "China" || echo "Other"
break
done

}

# export GITHUB_PROXY="https://gh-proxy.org"
export GITHUB_PROXY="https://cloudflare-proxy.xiechengqi.top"
