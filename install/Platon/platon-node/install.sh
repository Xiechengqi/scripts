#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/03
# Ubuntu 18.04
# https://github.com/PlatONnetwork/PlatON-Go
# install platon-node
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install_ntp() {
# evironments
local serviceName="ntp"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# install
EXEC "export DEBIAN_FRONTEND=noninteractive"      # disable interactive
EXEC "apt-get update && apt-get install -y gnupg2 curl software-properties-common ntp"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "$serviceName is running ..."
}

function main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# get chainId
chainId="$1" && INFO "chain: $chainId"                                                                                                
! echo "$chainId" | grep -E 'mainnet|testnet' &> /dev/null && ERROR "You could only choose chain: mainnet、testnet"
[ "$chainId" = "testnet" ] && ERROR "Platon testnet is not avaliable，See https://platon.network/galaxy/"

# install ntp
install_ntp

# environment
serviceName="platon-node"
version="1.0.0"
installPath="/data/Platon/${serviceName}-${version}"
port="16789"
rpcPort="6789"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,conf,logs,data}"

# download
EXEC "curl -SsL https://download.platon.network/platon/platon/${version}/platon -o $installPath/bin/platon"
EXEC "curl -SsL https://download.platon.network/platon/platon/${version}/platonkey -o $installPath/bin/platonkey"
EXEC "chmod +x $installPath/bin/*"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin/"
EXEC "platon version" && platon version

# create Node public private key
INFO "create Node public private key"
platonkey genkeypair | tee >(grep "PrivateKey" | awk '{print $2}' > ${installPath}/conf/nodekey) >(grep "PublicKey" | awk '{print $3}' > ${installPath}/conf/nodeid)


# create BLS public private key
INFO "create BLS public private key"
platonkey genblskeypair | tee >(grep "PrivateKey" | awk '{print $2}' > ${installPath}/conf/blskey) >(grep "PublicKey" | awk '{print $3}' > ${installPath}/conf/blspub)

# create start.sh
# get start options
if [ "$chainId" = "mainnet" ]
then
# mainnet
options="--identity platon --datadir ${installPath}/data --port ${port} --rpcport ${rpcPort} --rpcvhosts \"*\" --rpcapi \"db,platon,net,web3,admin,personal\" --rpc --nodekey ${installPath}/conf/nodekey --cbft.blskey ${installPath}/conf/blskey --verbosity 3 --rpcaddr 0.0.0.0 --syncmode \"fast\" --db.nogc --main"
else
# testnet
ERROR "Platon testnet is not avaliable，See https://platon.network/galaxy/"
# options="--identity platon --datadir ${installPath}/data --port ${port} --rpcport ${rpcPort} --rpcvhosts \"*\" --rpcapi \"db,platon,net,web3,admin,personal\" --rpc --nodekey ${installPath}/conf/nodekey --cbft.blskey ${installPath}/conf/blskey --verbosity 3 --rpcaddr 0.0.0.0 --syncmode \"fast\" --testnet"
fi

cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

platon $options &> $installPath/logs/$(date +%Y%m%d%H%M%S).log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Golang implementation of the PlatON protocol
Documentation=https://github.com/PlatONnetwork/PlatON-Go
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
YELLOW "config path: $installPath/conf"
YELLOW "log path: $installPath/logs"
YELLOW "db path: $installPath/data"
YELLOW "connection cmd: platon attach http://localhost:$rpcPort"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
