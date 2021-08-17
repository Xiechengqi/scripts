#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/17
# Ubuntu 18+
# install vet-node
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
serviceName="vet-node"
version="2.0.0-stage.0"
installPath="/data/Vet/${serviceName}-${version}"
downloadUrl="https://github.com/vechain/thor/archive/refs/tags/v${version}.tar.gz"
goUrl="$BASEURL/install/Golang/install.sh"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{src,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath/src"

# install golang
curl -SsL $goUrl | bash

# make install
EXEC "cd $installPath/src"
EXEC "make dep && make"

# register bin
EXEC "ln -fs $installPath/src/bin $installPath/bin"
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "thor -v" && thor -v

# create start.sh
[ "$chainId" = "mainnet" ] && options="--network main" || options="--network test"
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log

thor $options --api-addr 0.0.0.0:$rpcPort --data-dir $installPath/data &> $installPath/logs/latest.log
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
YELLOW "${serviceName} version: $version"
YELLOW "chain: ${chainId}"
YELLOW "rpc port: $rpcPort"
YELLOW "install path: $installPath"
YELLOW "config: $installPath/conf"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
