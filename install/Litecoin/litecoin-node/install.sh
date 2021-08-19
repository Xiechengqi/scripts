#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/19
# https://github.com/litecoin-project/litecoin
# Ubuntu 18+
# install Litecoin Node
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
serviceName="litecoin-node"
version="0.18.1"
installPath="/data/Litecoin/${serviceName}-${version}"
downloadUrl="https://download.litecoin.org/litecoin-${version}/linux/litecoin-${version}-x86_64-linux-gnu.tar.gz"
rpcUser="litecore"
rpcPassword="local321"
# use default port
[ "$chainId" = "mainnet" ] && rpcPort="9332" || rpcPort="19332"
[ "$chainId" = "mainnet" ] && p2pPort="9333" || p2pPort="19335"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{conf,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
INFO "litecoin-cli -version" && litecoin-cli -version

# conf
cat > $installPath/conf/${serviceName}.conf << EOF
server=1
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:29332
zmqpubhashblock=tcp://127.0.0.1:29332
rpcallowip=127.0.0.1
rpcuser=${rpcUser}
rpcpassword=${rpcPassword}
uacomment=litecore
EOF

# create start.sh
[ "$chainId" = "mainnet" ] && options="" || options="--testnet"
cat > $installPath/start.sh << EOF
#!/usr/bin/env /bash
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log
litecoind -conf=$installPath/conf/${serviceName}.conf --datadir=$installPath/data $options &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=Bitcoin Core integration/staging tree
Documentation=https://github.com/bitcoin/bitcoin
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
YELLOW "config: $installPath/conf"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "rpcPort: $rpcPort"
YELLOW "p2pPort: $p2pPort"
YELLOW "rpcUser: $rpcUser"
YELLOW "rpcPassword: $rpcPassword"
YELLOW "litecoin info cmd: litecoin-cli -conf=${installPath}/conf/${serviceName}.conf getblockchaininfo"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
