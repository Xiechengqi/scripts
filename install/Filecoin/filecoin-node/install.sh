#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/31
# install Filecoin node
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
serviceName="filecoin-node"
version="1.11.1"
installPath="/data/Filecoin/${serviceName}-${version}"
downloadUrl="https://github.com/filecoin-project/lotus/releases/download/v${version}/lotus_v${version}_linux-amd64.tar.gz"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,conf,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath/bin"

# install requirements
EXEC "export DEBIAN_FRONTEND=noninteractive"
EXEC "apt update && apt install -y mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl clang build-essential hwloc libhwloc-dev wget"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "lotus --version" && lotus --version

# create config file softlink
EXEC "ln -fs $installPath/data/config.toml $installPath/conf/config.toml"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env /bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d)
export GOLOG_FILE="\$installPath/logs/\${timestamp}.log"
export LOTUS_PATH="\$installPath/data"
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
lotus daemon &> /dev/null
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/filecoin-project/lotus
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
YELLOW "rpc port: 1234"
YELLOW "conf: $installPath/conf"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "check cmd: "
YELLOW "control cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
