#!/usr/bin/env bash

# 
# xiechengqi
# OS: 
# 2021/07/30
# install IRIS
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

function main() {
# environments
serviceName="iris-node"
version="1.1.1"
installPath="/data/${serviceName}-${version}"

# download url
golangUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Golang/install.sh"

# check service
iris version &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# install golang
curl -SsL $golangUrl | bash
source /etc/profile

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/logs"

# install build-essential
EXEC "apt update && apt install -y build-essential"

# install
EXEC "git clone -b 'v${version}'  https://github.com/irisnet/irishub $installPath/src"
EXEC "cd $installPath/src"
EXEC "make install"
EXEC "cd -"
EXEC "iris version"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/node"

# INFO
YELLOW "version: ${version}"
}

main
