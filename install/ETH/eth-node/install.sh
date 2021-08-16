#!/usr/bin/env bash

#
# xiechengqi
# 2021/08.03
# https://github.com/ethereum/go-ethereum https://geth.ethereum.org/
# Ubuntu 18.04
# install ETH Node Geth
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# get chainId
if [ "$1" = "mainnet" ]; then
chainId="mainnet"
curl -SsL $BASEURL/install/ETH/eth-node/geth_install.sh | bash -s $chainId
elif [ "$1" = "rinkey" ]; then
chainId="testnet"
curl -SsL $BASEURL/install/ETH/eth-node/geth_install.sh | bash -s $chainId
elif [ "$1" = "kovan" ]; then
chainId="kovan"
curl -SsL $BASEURL/install/ETH/eth-node/parity_install.sh | bash -s $chainId
else
ERROR "You could choose chain: mainnet、rinkey、kovan"
fi

}

main $@
