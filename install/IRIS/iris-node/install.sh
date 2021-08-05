#!/usr/bin/env bash

# 
# xiechengqi
# OS: Ubuntu 18.04
# 2021/08/03
# install IRIS Node
# 

source /etc/profile

OS() {
osType=$1
osVersion=$2
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/tool/os.sh | bash -s ${osType} ${osVersion} || exit 1
}

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
# check os
OS "ubuntu" "18"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"
[ "$net" = "testnet" ] && ERROR "IRIS testnet is not avaliable，See https://github.com/irisnet/irishub/issues/2644"

# environments
serviceName="iris-node"
version="1.0.1"
installPath="/data/IRIS/${serviceName}-${version}"

# download url
golangUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Golang/install.sh"
golangVersion="1.16.6"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# install golang
curl -SsL $golangUrl | bash -s ${golangVersion}
EXEC "source /etc/profile"

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{conf,logs}"

# install build-essential
EXEC "apt update && apt install -y build-essential"

# install
EXEC "git clone -b 'v${version}'  https://github.com/irisnet/irishub $installPath/src"
EXEC "cd $installPath/src"
EXEC "make install"
EXEC "cd -"

# register bin
EXEC "ln -fs $GOBIN/* /usr/local/bin"
EXEC "iris version" && iris version

# init mainnet node
EXEC "iris init iris-node --home=${installPath}/data --chain-id=irishub-1"

# download mainnet config.toml and genesis.json
EXEC "curl https://raw.githubusercontent.com/irisnet/mainnet/master/config/config.toml -o $installPath/data/config/config.toml"
EXEC "curl https://raw.githubusercontent.com/irisnet/mainnet/master/config/genesis.json -o $installPath/data/config/genesis.json"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

iris start --home=${installPath}/data &> $installPath/logs/$(date +%Y%m%d%H%M%S).log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=A BPoS blockchain that enables cross-chain interoperability through a unified service model
Documentation=https://github.com/irisnet/irishub
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
EXEC "ln -fs $installPath $(dirname $installPath)/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# INFO
YELLOW "version: ${version}"
}

main $@
