#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/09
# Ubuntu 18.04+
# https://docs.docker.com/engine/install/ubuntu/
# install docker
#

source /etc/profile

OS() {
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

_ubuntu() {
# remove old apps
apt-get remove docker docker-engine docker.io containerd runc &> /dev/null

# install requirements
EXEC "export DEBIAN_FRONTEND=noninteractive"
EXEC "apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release"

# add app source
EXEC "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
if [ "$countryCode" = "CN" ]
then
cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable
EOF
else
cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
EOF
fi

# install
EXEC "apt-get update && apt-get -y install docker-ce docker-ce-cli containerd.io"
}

_centos() {
INFO "yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine" && yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
EXEC "yum install -y yum-utils device-mapper-persistent-data lvm2"
EXEC "yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
[ "${countryCode}" = "CN" ] && EXEC "sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo" && EXEC "yum makecache fast"
EXEC "yum install -y docker-ce docker-ce-cli containerd.io"
}

main() {

# get os info
osInfo=`OS`

# environments
serviceName="docker"
countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

echo $osInfo | grep ubuntu &> /dev/null && _ubuntu
echo $osInfo | grep centos &> /dev/null && _centos

# start service
EXEC "systemctl start docker"

# check docker
EXEC "docker run hello-world"
}

main $@
