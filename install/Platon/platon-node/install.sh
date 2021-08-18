#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/18
# Ubuntu 18+
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
# [ "$chainId" = "testnet" ] && ERROR "Platon testnet is not avaliable，See https://platon.network/galaxy/"

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
options="--identity ${serviceName}-${chainId} --datadir ${installPath}/data --port ${port} --rpcport ${rpcPort} --rpcvhosts \"*\" --rpcapi \"db,platon,net,web3,admin,personal\" --rpc --nodekey ${installPath}/conf/nodekey --cbft.blskey ${installPath}/conf/blskey --verbosity 3 --rpcaddr 0.0.0.0 --syncmode \"fast\" --db.nogc --main"
else
# testnet - https://devdocs.platon.network/docs/zh-CN/Become_PlatON_Dev_Verification
EXEC "curl -SsL https://download.platon.network/platon/devnet/platon/1.0.0/genesis.json -o $installPath/conf/genesis.json"
EXEC "cd $installPath && platon --datadir ./data init ./conf/genesis.json"
EXEC "cd -"
options="--identity ${serviceName}-${chainId} --datadir $installPath/data --port ${port} --rpcport ${rpcPort} --rpcapi \"db,platon,net,web3,admin,personal\" --rpc --nodekey $installPath/conf/nodekey --cbft.blskey $installPath/conf/blskey --verbosity 3 --rpcaddr 0.0.0.0 --bootnodes enode://c72a4d2cb8228ca6f9072daa66566bcafa17bec6a9e53765c85c389434488c393357c5c7c5d18cf9b26ceda46aca4da20755cd01bcc1478fff891a201042ba84@devnetnode1.platon.network:16789 --syncmode \"fast\""
# ERROR "Platon testnet is not avaliable，See https://platon.network/galaxy/"
fi

cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log
platon $options &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
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
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs $installPath/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "rpc port: ${rpcPort}"
YELLOW "conf: $installPath/conf"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "connection cmd: platon attach http://localhost:$rpcPort"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
