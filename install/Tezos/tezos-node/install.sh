#!/usr/bin/env bash

#
# xiechnegqi
# 2021/08/09
# https://gitlab.com/tezos/tezos
# docker-compose install Tezos
#

source /etc/profile
source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

main() {

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
if [ "$net" = "mainnet" ]
then
# new install script url
installScriptUrl="https://gitlab.com/tezos/tezos/raw/latest-release/scripts/tezos-docker-manager.sh"
else
# old install script url
installScriptUrl="https://gitlab.com/tezos/tezos/raw/carthagenet/scripts/alphanet.sh"
fi
installPath="/data/Tezos/tezos-node"

# install script url
dockerUrl="https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/install.sh"
dockerComposeUrl="https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/docker-compose/install.sh"

# install docker and docker-compose
curl -SsL $dockerUrl | bash
curl -SsL $dockerComposeUrl | bash

# get install script name
[ "$net" = "mainnet" ] && fileName="mainnet" || fileName="carthagenet"

# check service
bash $installPath/${fileName}.sh status &> /dev/null && YELLOW "tezos-node is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath"

# install
EXEC "curl $installScriptUrl -o $installPath/${fileName}.sh"
EXEC "chmod +x $installPath/${fileName}.sh"

# forbid image auto update
cat > /etc/profile.d/tezos.sh << EOF
export TEZOS_ALPHANET_DO_NOT_PULL=yes
export TEZOS_MAINNET_DO_NOT_PULL=yes
EOF
EXEC "source /etc/profile.d/tezos.sh"

# start
EXEC "bash $installPath/${fileName}.sh start --rpc-port 0.0.0.0:8732"

# info
YELLOW "bash $installPath/${fileName}.sh node status" && bash $installPath/${fileName}.sh node status
YELLOW "look log: bash $installPath/${fileName}.sh node log"
}

main $@
