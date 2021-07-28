#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/28
# Ubuntu 18.04+
# install platon-node
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

function install_ntp() {
# evironments
local serviceName="ntp"

# check service
systemctl is-active $service &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# install
EXEC "apt-get update && apt-get install -y gnupg2 curl software-properties-common ntp"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager
}

function main() {

# install ntp
install_ntp

# environment
serviceName="platon-node"
version="1.0.0"
installPath="/data/Platon/${serviceName}-${version}"
port="16789"
rpcPort="6789"

# get args
if [ "$1" = "mainnet" ]
then
# mainnet
options="--identity platon --datadir ${installPath}/data --port ${port} --rpcport ${rpcPort} --rpcvhosts \"*\" --rpcapi \"db,platon,net,web3,admin,personal\" --rpc --nodekey ${installPath}/conf/nodekey --cbft.blskey ${installPath}/conf/blskey --verbosity 3 --rpcaddr 0.0.0.0 --syncmode \"fast\" --db.nogc --main"
else
# testnet
ERROR "Platon testnet is not avaliable，See https://platon.network/galaxy/" && return 1
# options="--identity platon --datadir ${installPath}/data --port ${port} --rpcport ${rpcPort} --rpcvhosts \"*\" --rpcapi \"db,platon,net,web3,admin,personal\" --rpc --nodekey ${installPath}/conf/nodekey --cbft.blskey ${installPath}/conf/blskey --verbosity 3 --rpcaddr 0.0.0.0 --syncmode \"fast\" --testnet"
fi

# check install path
EXEC "rm -rf $installPath && mkdir -p $installPath/{bin,conf,logs,data}"

# download
EXEC "curl -SsL https://download.platon.network/platon/platon/${version}/platon -o $installPath/bin/platon"
EXEC "curl -SsL https://download.platon.network/platon/platon/${version}/platonkey -o $installPath/bin/platonkey"
EXEC "chmod +x $installPath/bin/*"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/bin/"
EXEC "platon version" && platon version

# create Node public private key
INFO "create Node public private key"
platonkey genkeypair | tee >(grep "PrivateKey" | awk '{print $2}' > ${installPath}/conf/nodekey) >(grep "PublicKey" | awk '{print $3}' > ${installPath}/conf/nodeid)


# create BLS public private key
INFO "create BLS public private key"
platonkey genblskeypair | tee >(grep "PrivateKey" | awk '{print $2}' > ${installPath}/conf/blskey) >(grep "PublicKey" | awk '{print $3}' > ${installPath}/conf/blspub)

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash

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
YELLOW "config path: $installPath/conf"
YELLOW "log path: $installPath/logs"
YELLOW "db path: $installPath/data"
YELLOW "connection cmd: platon attach http://localhost:$rpcPort"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
