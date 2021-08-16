#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/16
# Ubuntu 20.04
# install chainx-node
#

source /etc/profile
source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

main() {

# check os
OS "ubuntu" "20"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
serviceName="chainx-node"
version="3.0.0"
installPath="/data/ChainX/${serviceName}-${version}"
downloadUrl="https://github.com/chainx-org/ChainX/releases/download/v${version}/chainx-v${version}-ubuntu-20.04-x86_64-unknown-linux-gnu"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,conf,data,logs}"

# download tarball
EXEC "curl -SsL $downloadUrl -o $installPath/bin/chainx"


# register bin
EXEC "chmod +x $installPath/bin/chainx"
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "chainx -V" && chainx -V

# conf
cat > $installPath/conf/${serviceName}.json << EOF
{
  "log-dir": "$installPath/logs",
  "enable-console-log": true,
  "no-mdns": true,
  "ws-external": true,
  "rpc-external": true,
  "rpc-cors": "all",
  "log": "info,runtime=info",
  "port": 20222,
  "ws-port": 8087,
  "rpc-port": 8086,
  "pruning": "archive", 
  "execution": "NativeElseWasm",
  "db-cache": 2048, 
  "state-cache-size": 2147483648, 
  "name": "ChainX-Node",
  "base-path": "$installPath/data", 
  "bootnodes": []
}
EOF

# create start.sh
[ "$net" = "mainnet" ] && chainId="mainnet" || chainId="testnet"
cat > $installPath/start.sh << EOF
#!/usr/bin/env
source /etc/profile

chainx --chain=${chainId} --config $installPath/conf/${serviceName}.json
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=Chainx Node
Documentation=https://github.com/chainx-org/ChainX
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
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "data path: $installPath/data"
YELLOW "log path: $installPath/logs"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
