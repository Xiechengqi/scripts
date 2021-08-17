#!/usr/bin/env bash

#
# xiechnegqi
# 2021/08/17
# https://github.com/stellar/docker-stellar-core-horizon
# https://github.com/stellar/stellar-core
# docker install Stellar
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|centos7|centos8' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、centos7、centos8"

# get chainId
chainId="$1" && INFO "chain: $chainId"                                                                                                
! echo "$chainId" | grep -E 'mainnet|testnet' &> /dev/null && ERROR "You could only choose chain: mainnet、testnet"

serviceName="stellar-node"
installPath="/data/${serviceName}"
dockerUrl="$BASEURL/Docker/install.sh"

# check service
docker ps -a | grep ${serviceName} &> /dev/null && ERROR "${serviceName} is running ..."

# install docker
curl -SsL $dockerUrl | bash

# docker run service
[ "$chainId" = "mainnet" ] && options="--pubnet" || options="--testnet"
EXEC "docker run -itd --restart=always -p 8000:8000 -v $installPath/data:/opt/stellar --name ${serviceName} stellar/quickstart $options"

# check
EXEC "sleep 5"
EXEC "docker ps | grep ${serviceName}"

# info
YELLOW "log: docker logs -f $serviceName"
YELLOW "data: $installPath/data"
YELLOW "managemanet cmd: docker [stop|start|restart] $serviceName"
}

main $@
