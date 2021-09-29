#!/usr/bin/env bash

#
# xiechengqi
# OS: Ubuntu 18+
# 2021/09/29
# https://github.com/irisnet/irishub
# install IRIS Node
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
# [ "$chainId" = "testnet" ] && ERROR "IRIS testnet is not avaliable，See https://github.com/irisnet/irishub/issues/2644"

# environments
serviceName="iris-node"
version="1.0.1"
installPath="/data/IRIS/${serviceName}-${version}"

# download url
golangUrl="$BASEURL/install/Golang/install.sh"
golangVersion="1.16.6"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# install golang
curl -SsL $golangUrl | bash -s ${golangVersion}
EXEC "source /etc/profile"

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/logs"

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

# initialize node configurations
EXEC "iris init iris-node --home=${installPath}/data --chain-id=irishub-1"

# download config.toml and genesis.json
if [ "$chainId" = "mainnet" ]; then
EXEC "curl -SsL https://raw.githubusercontent.com/irisnet/mainnet/master/config/config.toml -o $installPath/data/config/config.toml"
EXEC "curl -SsL https://raw.githubusercontent.com/irisnet/mainnet/master/config/genesis.json -o $installPath/data/config/genesis.json"
else
EXEC "curl -SsL https://raw.githubusercontent.com/irisnet/testnets/master/nyancat/config/config.toml -o $installPath/data/config/config.toml"
EXEC "curl -SsL https://raw.githubusercontent.com/irisnet/testnets/master/nyancat/config/genesis.json -o $installPath/data/config/genesis.json"
fi

# link conf
EXEC "ln -fs $installPath/data/config $installPath/conf"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath=$installPath
timestamp=$(date +%Y%m%d-%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
iris start --home=\$installPath/data &> \$installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
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
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# INFO
YELLOW "${serviceName} version: $version"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "data path: $installPath/data"
YELLOW "tail log cmd: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"

}

main $@
