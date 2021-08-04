#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/23
# install node
#

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
# environment
version=${1-"12.16.0"}
installPath="/data/node-${version}"
downloadUrl="https://nodejs.org/download/release/v${version}/node-v${version}-linux-x64.tar.gz"

# check node
node -v &> /dev/null && YELLOW "node has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "sed -i '/node\/bin/d' /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
EXEC "ln -fs $installPath/bin/* /usr/bin/"
EXEC "source /etc/profile"
EXEC "node -v" && node -v
EXEC "npm -v" && npm -v

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/node"

# info
YELLOW "version: $version"
}

main $@
