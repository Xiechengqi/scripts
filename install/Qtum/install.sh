#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/10
# https://github.com/qtumproject/qtum
# Ubuntu 18.04
# install qtum
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
OS "ubuntu" "18"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
serviceName="qtum-node"
version="0.20.3"
installPath="/data/Qtum/${serviceName}-${versioin}"
downloadUrl="https://github.com/qtumproject/qtum/releases/download/mainnet-fastlane-v${version}/qtum-${version}-x86_64-linux-gnu.tar.gz"
rpcUser="user"
rpcPassword="password"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{conf,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "qtumd -version" && qtumd -version

# conf
cat > $installPath/conf/${serviceName}.conf << EOF
logevents=1
rpcuser=$rpcUser
rpcpassword=$rpcPassword
EOF

# create start.sh
[ "$net" = "mainnet" ] && options="" || options="-testnet"
cat > $installPath/start.sh << EOF
#!/usr/bin/env
source /etc/profile

qtumd $options -datadir=$installPath/data -conf=$installPath/conf/${serviceName}.conf -debuglogfile=$installPath/logs/\$(date +%Y%m%d%H%M%S).log 
EOF

# info
# curl --user myusername --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getinfo", "params": [] }' -H 'content-type: text/plain;' http://127.0.0.1:3889/
YELLOW "version: $version"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "log path: $installPath/logs"
YELLOW "data path: $installPath/data"
YELLOW "blockchain info cmd: qtum-cli -conf=${installPath}/conf/${serviceName}.conf getinfo"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
