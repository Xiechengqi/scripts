#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/16
# https://github.com/openethereum/openethereum
# Install ETH Chain By Parity(openethereum)
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os`
! echo "$countryCode" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && EXEC "You could only install on os: ubuntu18、ubuntu20"

chainId=$1

# environments
serviceName="eth-node"
version="3.2.6"
installPath="/data/${serviceName}-${version}"
downloadUrl="https://github.com/openethereum/openethereum/releases/download/v${version}/openethereum-linux-v${version}.zip"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,conf,logs}"

# install unzip
EXEC "apt update && apt install -y unzip"

# download
EXEC "rm -rf /tmp/${serviceName} && mkdir /tmp/${serviceName}"
EXEC "curl -SsL $downloadUrl -o /tmp/${serviceName}/${serviceName}.zip"
EXEC "unzip /tmp/${serviceName}/${serviceName}.zip -d ${installPath}/bin"

# register bin
EXEC "chmod +x $installPath/bin/*"
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "openethereum -v" && openethereum -v

# config
cat > $installPath/conf/config.toml << EOF
[parity]
chain = "$chainId"
base_path = "$installPath/data"

[rpc]
interface = "0.0.0.0"

[websockets]
interface = "0.0.0.0"
EOF

# create start.sh
## --chain=[CHAIN] Specify the blockchain type. CHAIN may be either a JSON chain specification file or ethereum, poacore, xdai, volta, ewc, musicoin, ellaism, mix, callisto, morden, ropsten, kovan, rinkeby, goerli, poasokol, testnet, or dev. (default: foundation)
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log
openethereum --conf=$installPath/conf/config.toml &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=ETH Node
Documentation=https://github.com/openethereum/openethereum
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
YELLOW "config: $installPath/conf"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
