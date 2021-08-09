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
osType=$1
osVersion=$2
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/tool/os.sh | bash -s ${osType} ${osVersion} || exit 1
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

main() {

# check os
OS "ubuntu"

# environments
serviceName="docker"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# remove old apps
apt-get remove docker docker-engine docker.io containerd runc &> /dev/null

# install requirements
EXEC "export DEBIAN_FRONTEND=noninteractive"
EXEC "apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release"

# add app source
EXEC "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
EOF

# install
EXEC "apt-get update && apt-get -y install docker-ce docker-ce-cli containerd.io"
 
# check docker
EXEC "docker run hello-world"
}

main $@
