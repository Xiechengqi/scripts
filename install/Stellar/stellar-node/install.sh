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

# environments
serviceName="stellar-node"
installPath="/data/Stellar/${serviceName}"
port="8000"
dockerUrl="$BASEURL/install/Docker/install.sh"

# check service
docker ps -a | grep ${serviceName} &> /dev/null && ERROR "${serviceName} is running ..."

# install docker
curl -SsL $dockerUrl | bash

# docker run service
[ "$chainId" = "mainnet" ] && options="--pubnet" || options="--testnet"
INFO "init postgresql and set postgresql password, then use CTRL C to break out this init container ..."
EXEC "docker run --rm -it -p $port:8000 -v $installPath/data:/opt/stellar --name ${serviceName} stellar/quickstart $options"
EXEC "sed 's/PER_HOUR_RATE_LIMIT=.*/PER_HOUR_RATE_LIMIT=72000000/' horizon.env"
EXEC "docker run -itd --restart=always -p $port:8000 -v $installPath/data:/opt/stellar --name ${serviceName} stellar/quickstart $options"

# check
EXEC "sleep 5"
INFO "docker ps | grep ${serviceName}" && docker ps | grep ${serviceName}
INFO "curl 127.0.0.1:$port | grep core_latest_ledger" && curl 127.0.0.1:$port | grep core_latest_ledger

# info
YELLOW "port: $port"
YELLOW "log: docker logs -f $serviceName"
YELLOW "data: $installPath/data"
YELLOW "managemanet cmd: docker [stop|start|restart] $serviceName"
}

main $@
