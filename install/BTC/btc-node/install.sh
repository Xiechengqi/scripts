#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/03
# https://github.com/bitcoin/bitcoin
# Ubuntu 18.04
# install bitcoin
#

source /etc/profile
source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

main() {
# check os
OS "ubuntu" "18"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
serviceName="btc-node"
version="0.21.1"
installPath="/data/BTC/${serviceName}-${version}"
downloadUrl="https://bitcoincore.org/bin/bitcoin-core-${version}/bitcoin-${version}-x86_64-linux-gnu.tar.gz"
rpcUser="bitcoin"
rpcPassword="local321"
[ "$net" = "mainnet" ] && rpcPort="8332" || rpcPort="18332"
[ "$net" = "mainnet" ] && p2pPort="8333" || p2pPort="18333"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{conf,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "sed -i '/btc-node.*\/bin/d' /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
EXEC "ln -fs $installPath/bin/* /usr/local/bin/"
EXEC "source /etc/profile"
EXEC "bitcoin-cli -version" && bitcoin-cli -version

# config
[ "$1" = "mainnet" ] && ifTestnet="0" || ifTestnet="1"    # get testnet or mainnet
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
uacomment=bitcore
EOF

# create start.sh
[ "$net" = "mainnet" ] && options="" || options="--testnet"
cat > $installPath/start.sh << EOF
#!/usr/bin/env /bash
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log
bitcoind -conf=$installPath/conf/${serviceName}.conf $options &> $installPath/logs/latest.log
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
YELLOW "version: $version"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "tail log cmd: tail -f $installPath/logs/latest.log"
YELLOW "data path: $installPath/data"
YELLOW "rpcUser: $rpcUser"
YELLOW "rpcPassword: $rpcPassword"
YELLOW "rpcPort: $rpcPort"
YELLOW "p2pPort: $p2pPort"
YELLOW "blockchain info cmd: bitcoin-cli -conf=${installPath}/conf/${serviceName}.conf getblockchaininfo"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
