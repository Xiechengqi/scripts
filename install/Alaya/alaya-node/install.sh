#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/19
# https://devdocs.alaya.network/alaya-devdocs/zh-CN/Run_a_fullnode/
# install Alaya Node
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

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# get chainId
chainId="$1" && INFO "chain: $chainId"                                                                                                
! echo "$chainId" | grep -E 'mainnet|testnet' &> /dev/null && ERROR "You could only choose chain: mainnet、testnet"

# environments
serviceName="alaya-node"
version="0.16.0"
installPath="/data/Alaya/${serviceName}-${version}"
port="16790"
rpcPort="6790"

# check service
docker ps -a | grep ${serviceName} &> /dev/null && ERROR "${serviceName} is running ..."

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,conf,data,logs}"

# install ntp
install_ntp

# download
EXEC "curl -SsL https://download.alaya.network/alaya/platon/${version}/alaya -o $installPath/bin/alaya"
EXEC "curl -SsL https://download.alaya.network/alaya/platon/${version}/alayakey -o $installPath/bin/alayakey"

# register bin
EXEC "chmod +x $installPath/bin/*" 
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
INFO "alaya version" && alaya version

# create Node public private key
alayakey genkeypair | tee >(grep "PrivateKey" | awk '{print $2}' > $installPath/conf/nodekey) >(grep "PublicKey" | awk '{print $3}' > $installPath/conf/nodeid)

# create BLS public private key
alayakey genblskeypair | tee >(grep "PrivateKey" | awk '{print $2}' > $installPath/conf/blskey) >(grep "PublicKey" | awk '{print $3}' > $installPath/conf/blspub)


# create start.sh
## --identity	指定网络名称
## --datadir	指定 data 目录路径
## --port	p2p端口号
## --rpcaddr	指定 rpc 服务器地址
## --rpcport	指定 rpc 协议通信端口
## --rpcapi	指定节点开放的 rpcapi 名称
## --rpc	指定 http-rpc 通讯方式
## --nodekey	指定节点私钥文件
## --cbft.blskey	指定节点 bls 私钥文件 （非验证节点即全节点，该参数为可选）
## --verbosity	日志级别，0: CRIT; 1: ERROR； 2: WARN; 3: INFO; 4: DEBUG； 5: TRACE
## --syncmode	fast：快速同步模式，full：全同步模式
## –db.nogc	开启归档模式
if [ "$chainId" = "mainnet" ]; then

cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile


installPath=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
timestamp=$(date +%Y%m%d)
touch \$installPath/logs/${timestamp}.log && ln -fs \$installPath/logs/${timestamp}.log \$installPath/logs/latest.log
alaya --identity ${serviceName}-${chainId} --datadir \$installPath/data --port $port --rpcaddr 0.0.0.0 --rpcport $rpcPort --rpc --rpcapi "db,platon,net,web3,admin,personal" --nodekey \$installPath/conf/nodekey --cbft.blskey \$installPath/conf/blskey --verbosity 3 --syncmode "fast" &> \$installPath/logs/latest.log
EOF

else

# download genesis.json
EXEC "curl -SsL https://download.alaya.network/alaya/platon/0.15.1/genesis.json -o $installPath/conf/genesis.json"

# init genesis.json 
EXEC "alaya --datadir $installPath/data init $installPath/conf/genesis.json"
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
timestamp=$(date +%Y%m%d)
touch \$installPath/logs/${timestamp}.log && ln -fs \$installPath/logs/${timestamp}.log \$installPath/logs/latest.log
alaya --identity ${serviceName}-${chainId} --datadir \$installPath/data --port $port --rpcport $rpcPort --rpcapi "db,platon,net,web3,admin,personal" --rpc --nodekey \$installPath/conf/nodekey --cbft.blskey \$installPath/conf/blskey --verbosity 3 --rpcaddr 0.0.0.0 --bootnodes enode://48f9ebd7559b7849f80e00d89d87fb92604c74a541a7d76fcef9f2bcc67043042dfab0cfbaeb5386f921208ed9192c403f438934a0a39f4cad53c55d8272e5fb@devnetnode1.alaya.network:16789 --syncmode "fast" &> \$installPath/logs/latest.log
EOF

fi
EXEC "chmod +x $installPath/start.sh"

cat > ${installPath}/${serviceName}.service << EOF 
[Unit]
Description=${serviceName}
Documentation=https://github.com/AlayaNetwork/Alaya-Go
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
YELLOW "check cmd: alaya attach http://localhost:$rpcPort"
YELLOW "control cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
