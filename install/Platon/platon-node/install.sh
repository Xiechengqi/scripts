#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/26
# install platon
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
# environment
serviceName="platon"
version="1.0.0"
installPath="/data/Platon/platon-node-${version}"
port="16789"
rpcPort="6789"

# check install path
EXEC "rm -rf $installPath && mkdir -p $installPath/{bin,conf,logs,data}"

# download
EXEC "curl -SsL https://download.platon.network/platon/platon/${version}/platon -o $installPath/bin"
EXEC "curl -SsL https://download.platon.network/platon/platon/${version}/platonkey -o $installPath/bin"
EXEC "chmod +x $installPath/bin/*"

# register bin
EXEC "ln -fs $installPath/platon /usr/bin/platon"
EXEC "ln -fs $installPath/platonkey /usr/bin/platonkey"
EXEC "platon version" && platon version

# create Node public private key
EXEC "platonkey genkeypair | tee >(grep 'PrivateKey' | awk '{print $2}' > ${installPath}/data/nodekey) >(grep 'PublicKey' | awk '{print $3}' > ${installPath}/data/nodeid)"

# create BLS public private key
EXEC "platonkey genblskeypair | tee >(grep 'PrivateKey' | awk '{print $2}' > ${installPath}/data/blskey) >(grep 'PublicKey' | awk '{print $3}' > ${installPath}/data/blspub)"

# create start.sh
if [ "$1" = "mainnet" ]
then
options="–identity platon –datadir $installPath/data –port $port –db.nogc –rpcvhosts * –rpcport $rpcPort –rpcapi \"db,platon,net,web3,admin,personal\" –rpc –nodekey $installPath/data/nodekey –cbft.blskey $installPath/data/blskey –verbosity 3 –rpcaddr 0.0.0.0 –syncmode \"full\""
else
options="–identity platon –datadir $installPath/data –port $port –db.nogc –rpcvhosts * –rpcport $rpcPort –rpcapi \"db,platon,net,web3,admin,personal\" –rpc –nodekey $installPath/data/nodekey –cbft.blskey $installPath/data/blskey –verbosity 3 –rpcaddr 0.0.0.0 –syncmode \"full\" –testnet"
fi
cat > $installPath/start.sh << EOF
INFO "platon $options &> $installPath/logs/platon.log"
platon $options &> $installPath/logs/platon.log
EOF

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Golang implementation of the PlatON protocol
Documentation=https://github.com/PlatONnetwork/PlatON-Go

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
YELLOW "connection cmd: palton attach http://localhost:$rpcPort"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
