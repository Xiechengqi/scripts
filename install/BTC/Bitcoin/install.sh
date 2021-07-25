#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/14
# install bitcoin
#

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
# environments
serviceName="bitcoin"
version="0.21.1"
installPath="/data/BTC/${serviceName}-${version}"
downloadUrl="https://bitcoincore.org/bin/bitcoin-core-${version}/bitcoin-${version}-x86_64-linux-gnu.tar.gz"
rpcUser="bitcorenodetest"
rpcPassword="local321"
rpcPort="18332"
p2pPort="18333"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{conf,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "sed -i '/bitcoin.*\/bin/d' /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
EXEC "ln -fs $installPath/bin/* /usr/bin/"
EXEC "source /etc/profile"
EXEC "bitcoin-cli -version" && bitcoin-cli -version

# config
[ "$1" = "mainnet" ] && ifTestnet="0" || ifTestnet="1"    # get testnet or mainnet
cat > $installPath/conf/${serviceName}.conf << EOF
datadir=$installPath/data
testnet=${ifTestnet}
server=1
whitebind=127.0.0.1:$p2pPort
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubhashtx=tcp://127.0.0.1:28333
zmqpubhashblock=tcp://127.0.0.1:28334
zmqpubrawblock=tcp://127.0.0.1:28335
rpcallowip=0.0.0.0/0
rpcport=$rpcPort
rpcuser=$rpcUser
rpcpassword=$rpcPassword
uacomment=bitcore
EOF

# create start.sh
[ "$1" != "mainnet" ] && options="--testnet"    # get options
cat > $installPath/start.sh << EOF
#!/usr/bin/env /bash

$installPath/bin/bitcoind $options --rpcport=$rpcPort --rpcbind=0.0.0.0 -conf=$installPath/conf/${serviceName}.conf &> $installPath/logs/${serviceName}.log
EOF

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Bitcoin Core integration/staging tree
Documentation=https://github.com/bitcoin/bitcoin

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
EXEC "systemctl daemon-reload && systemctl enable --now $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "version: $version"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "log path: $installPath/logs"
YELLOW "data path: $installPath/data"
YELLOW "rpcUser: $rpcUser"
YELLOW "rpcPassword: $rpcPassword"
YELLOW "rpcPort: $rpcPort"
YELLOW "p2pPort: $p2pPort"
YELLOW "connection cmd: "
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
