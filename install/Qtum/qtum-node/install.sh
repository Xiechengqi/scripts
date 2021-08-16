#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/11
# https://github.com/qtumproject/qtum
# Ubuntu 18.04
# install qtum-node
#

source /etc/profile
source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

main() {

# check os
OS "ubuntu" "18"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
serviceName="qtum-node"
version="0.20.3"
installPath="/data/Qtum/${serviceName}-${version}"
downloadUrl="https://github.com/qtumproject/qtum/releases/download/mainnet-fastlane-v${version}/qtum-${version}-x86_64-linux-gnu.tar.gz"
rpcUser="user"
rpcPassword="password"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{conf,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "qtumd -version" && qtumd -version

# conf
cat > $installPath/conf/${serviceName}.conf << EOF
logevents=1
rpcuser=$rpcUser
rpcpassword=$rpcPassword
EOF

# create start.sh
[ "$net" = "mainnet" ] && options="" || options="-testnet"
cat > $installPath/start.sh << EOF
#!/usr/bin/env
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log
qtumd $options -datadir=$installPath/data -conf=$installPath/conf/${serviceName}.conf -debuglogfile=$installPath/logs/latest.log 
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=Qtum Node
Documentation=https://github.com/qtumproject/qtum
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
# curl --user myusername --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getinfo", "params": [] }' -H 'content-type: text/plain;' http://127.0.0.1:3889/
YELLOW "${serviceName} version: $version"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "data path: $installPath/data"
YELLOW "tail log cmd: tail -f $installPath/logs/latest.log"
YELLOW "blockchain info cmd: alias qtum-cli=\"qtum-cli -conf=${installPath}/conf/${serviceName}.conf ${options}\" && qtum-cli getblockchaininfo"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
