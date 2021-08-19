#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/19
# Ubuntu 18+
# install ETH Node
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# get chainId
chainId=$1

# install
if [ "$chainId" = "mainnet" ]; then
curl -SsL $BASEURL/install/ETH/eth-node/geth_install.sh | bash -s $chainId
elif [ "$chainId" = "rinkey" ]; then
chainId="testnet"
curl -SsL $BASEURL/install/ETH/eth-node/geth_install.sh | bash -s $chainId
elif [ "$chainId" = "kovan" ]; then
chainId="kovan"
curl -SsL $BASEURL/install/ETH/eth-node/parity_install.sh | bash -s $chainId
else
ERROR "You could choose chain: mainnet、rinkey、kovan"
fi

}

main $@
