#!/usr/bin/env bash
{

#
# xiechengqi
# 2021/07/22
# https://github.com/ethereum/go-ethereum
# Ubuntu 16+
# binary install Geth
# for mainnet, need to open firewall port: 30303/tcp 30303/udp 8545/tcp
# https://geth.ethereum.org/
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

# get chainType
chainType="$1"
[ "$chainType" = "" ] && chainType="testnet"

# environments
version="1.10.5-33ca98ec"
installPath="/data/ETH/geth-${version}"
downloadUrl="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-${version}.tar.gz"
wsport="8544"
serviceName="eth"

# check geth
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{data,logs}"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register bin
EXEC "ln -fs $installPath/geth /usr/bin/geth"
EXEC "geth version" && geth version

# create start.sh
pubIp=`curl -4 ip.sb`    # get vm public ip
if [ "$chainType" = "mainnet" ]
then
options="--nat=extip:$pubIp --http --http.addr 0.0.0.0 --ws --ws.addr 0.0.0.0 --ws.port $wsport --datadir $installPath/data --http.vhosts=*"
else
options="--nat=extip:$pubIp --http --http.addr 0.0.0.0 --ws --ws.addr 0.0.0.0 --ws.port $wsport --datadir $installPath/data --http.vhosts=* --rinkeby"
fi
cat > $installPath/start.sh << EOF
$installPath/geth $options &> $installPath/logs/geth.log
EOF
chmod +x $installPath/start.sh

# register service
cat > /lib/systemd/system/$serviceName.service << EOF
[Unit]
Description=Official Go implementation of the Ethereum protocol
Documentation=https://github.com/ethereum/go-ethereum

[Service]
User=root
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
YELLOW "connection cmd: geth attach http://localhost:8545"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
}
