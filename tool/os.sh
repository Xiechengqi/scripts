#!/usr/bin/env bash

# 
# xiechengqi
# 2021/08/02
# 操作系统信息
# Usage: curl -SsL https://xxx.os.sh | bash -s Ubuntu 16.04
#

source /etc/profile

INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
}

YELLOW() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[33m%s\033[0m" "$1"
printf "\n"
}

ERROR() {
printf -- "\033[41;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
exit 1
}

EXEC() {
local cmd="$1"
INFO "${cmd}"
eval ${cmd} 1> /dev/null
if [ $? -ne 0 ]; then
ERROR "Execution command (${cmd}) failed, please check it and try again."
fi
}

_os() {
local os=""
[ -f "/etc/debian_version" ] && source /etc/os-release && os="${ID}" && printf -- "%s" "${os}" && return
[ -f "/etc/fedora-release" ] && os="fedora" && printf -- "%s" "${os}" && return
[ -f "/etc/redhat-release" ] && os="centos" && printf -- "%s" "${os}" && return
}

_os_full() {
[ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
[ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
[ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

_os_ver() {
local main_ver="$( echo $(_os_full) | grep -oE  "[0-9.]+")"
printf -- "%s" "${main_ver%%.*}"
}

function main() {
osCheck=${1}
osVersionCheck=${2}
[ ".${osCheck}" = "." ] && ERROR "Usage: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/tool/os.sh | bash -s [OS] [Version]"
[ ".${osVersionCheck}" = "." ] && ifOsVersionCheck="false" || ifOsVersionCheck="true"
ifOsVersionRight="true"
ifOsRight="false"
osReal=`_os`
osVersionReal=`_os_ver`
YELLOW "current os info: ${osReal}${osVersionReal}"
echo $osReal | grep -qwi $osCheck && ifOsRight="true"
[ "${ifOsVersionCheck}" = "true" ] && ! echo $osVersionReal | grep -qwi $osVersionCheck && ifOsVersionRight="false"
[ "${ifOsVersionRight}" = "true" ] && [ "${ifOsVersionRight}" = "true" ] || ERROR "recommended os info: ${osCheck}${osVersionCheck}"
}

main $@
