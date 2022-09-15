#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/24
# https://github.com/ethereum/go-ethereum
# https://geth.ethereum.org/
# Ubuntu 18+
# geth install ETH Node
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# get chainId
chainId="$1" && INFO "chain: $chainId"
! echo "$chainId" | grep -E 'mainnet|testnet' &> /dev/null && ERROR "You could only choose chain: mainnet、testnet"

# environments
serviceName="eth-node"
# version="1.10.8-26675454"
version="1.10.24-972007a5"
installPath="/data/ETH/${serviceName}-${version}"
downloadUrl="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-${version}.tar.gz"
wsPort="8544"
rpcPort="8545"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,data,logs}"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register bin
EXEC "mv $installPath/geth $installPath/bin"
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "geth version" && geth version

# create start.sh
pubIp=`curl -4 ip.sb`    # get vm public ip
[ "$chainId" = "mainnet" ] && options="" || options="--$chainId"
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="$installPath"
timestamp=\$(date +%Y%m%d%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
geth --nat=extip:$pubIp --http --http.addr 0.0.0.0 --ws --ws.addr 0.0.0.0 --ws.port $wsPort --datadir \$installPath/data --http.vhosts=* $options &> \$installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
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
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs $installPath/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "chain: $chainId"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "info cmd: geth attach http://$(hostname -I | awk '{print $1}'):${rpcPort} --exec 'eth.syncing'"
YELLOW "control cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
