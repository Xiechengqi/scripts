#!/usr/bin/env bash

#
# xiechengqi
# 2021/08.03
# https://github.com/ethereum/go-ethereum https://geth.ethereum.org/
# Ubuntu 18.04
# install ETH Node Geth
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

function main() {
# check os
OS "ubuntu" "18"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
serviceName="eth-node"
version="1.10.5-33ca98ec"
installPath="/data/ETH/${serviceName}-${version}"
downloadUrl="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-${version}.tar.gz"
wsPort="8544"
rpcPort="8545"

# check geth
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{data,logs}"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register bin
EXEC "ln -fs $installPath/geth /usr/local/bin/geth"
EXEC "geth version" && geth version

# create start.sh
pubIp=`curl -4 ip.sb`    # get vm public ip
[ "$net" = "mainnet" ] && options="" || options="--rinkeby"
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

geth --nat=extip:$pubIp --http --http.addr 0.0.0.0 --ws --ws.addr 0.0.0.0 --ws.port $wsPort --datadir $installPath/data --http.vhosts=* $options &> $installPath/logs/$(date +%Y%m%d%H%M%S).log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Official Go implementation of the Ethereum protocol
Documentation=https://github.com/ethereum/go-ethereum
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "version: $version"
YELLOW "install path: $installPath"
YELLOW "log path: $installPath/logs"
YELLOW "db path: $installPath/data"
YELLOW "connection cmd: geth attach http://${pubIp}:${rpcPort}"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
