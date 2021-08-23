#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/23
# https://github.com/bitcoin/bitcoin
# Ubuntu 18+
# install BTC Node
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
serviceName="btc-node"
version="0.21.1"
installPath="/data/BTC/${serviceName}-${version}"
downloadUrl="https://bitcoincore.org/bin/bitcoin-core-${version}/bitcoin-${version}-x86_64-linux-gnu.tar.gz"
rpcUser="bitcoin"
rpcPassword="local321"
[ "$chainId" = "mainnet" ] && rpcPort="8332" || rpcPort="18332"
[ "$chainId" = "mainnet" ] && p2pPort="8333" || p2pPort="18333"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{conf,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "ln -fs $installPath/bin/* /usr/local/bin/"
EXEC "bitcoin-cli -version" && bitcoin-cli -version

# config
cat > $installPath/conf/${serviceName}.conf << EOF
datadir=$installPath/data
server=1
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubhashblock=tcp://127.0.0.1:28332
rpcallowip=127.0.0.1
rpcuser=${rpcUser}
rpcpassword=${rpcPassword}
EOF

# create start.sh
[ "$chainId" = "mainnet" ] && options="" || options="--testnet"
cat > $installPath/start.sh << EOF
#!/usr/bin/env /bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
bitcoind -conf=\$installPath/conf/${serviceName}.conf $options &> \$installPath/logs/latest.log
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
YELLOW "chain: ${chainId}"
YELLOW "rpc port: $rpcPort"
YELLOW "p2p port: $p2pPort"
YELLOW "rpc user: $rpcUser"
YELLOW "rpc password: $rpcPassword"
YELLOW "conf: $installPath/conf"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "check cmd: bitcoin-cli -conf=${installPath}/conf/${serviceName}.conf getblockchaininfo"
YELLOW "control cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
