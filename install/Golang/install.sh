#!/usr/bin/env bash

# 
# xiechengqi
# OS: all linux
# 2021/07/30
# binary install golang 
# curl -SsL https://xxx/install.sh | bash -s Go版本号
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
serviceName="golang"
version=${1-"1.16.6"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://golang.org/dl/go${version}.linux-amd64.tar.gz"

# check service
go version &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{data,path}"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath/data"

# register path
EXEC "sed -i '/golang\/bin/d' /etc/profile"
EXEC "echo 'export GOPATH=$installPath/path' >> /etc/profile"
EXEC "echo 'export GOBIN=\$GOPATH/bin' >> /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/data/bin:\$GOBIN' >> /etc/profile"
EXEC "ln -fs $installPath/data/bin/* /usr/local/bin/"
EXEC "source /etc/profile"
EXEC "go version"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/${serviceName}"

# info
YELLOW "version: ${version}"
}

main $@
