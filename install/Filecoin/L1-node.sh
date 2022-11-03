#!/usr/bin/env bash

#
# 2022/10/29
# xiechengqi
# filecoin-saturn-l1-node setup
# https://raw.githubusercontent.com/filecoin-saturn/L1-node/main/run.sh
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

# install docker
curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/install.sh | sudo bash -s verison

export FIL_WALLET_ADDRESS=${1-"f1b7kiglcp6sl67lsttw6oxjyge3tfueybdcsaefy"}
export NODE_OPERATOR_EMAIL="xiechengqi01@gmail.com"
export SATURN_NETWORK="main"
export SATURN_HOME="/data/filecoin-saturn-l1-node"
EXEC "mkdir -p ${SATURN_HOME}"
# : "${SATURN_NETWORK:=test}"

INFO "Running Saturn $SATURN_NETWORK network L1 Node on $SATURN_HOME"
EXEC "docker rm -f saturn-node || true"
INFO "docker run --name saturn-node -it -d --restart=unless-stopped -v $SATURN_HOME/shared:/usr/src/app/shared -e FIL_WALLET_ADDRESS=$FIL_WALLET_ADDRESS -e NODE_OPERATOR_EMAIL=$NODE_OPERATOR_EMAIL --network host --ulimit nofile=1000000 ghcr.io/filecoin-saturn/l1-node:$SATURN_NETWORK"
docker run --name saturn-node -it -d \
  --restart=unless-stopped \
  -v $SATURN_HOME/shared:/usr/src/app/shared \
  -e FIL_WALLET_ADDRESS=$FIL_WALLET_ADDRESS \
  -e NODE_OPERATOR_EMAIL=$NODE_OPERATOR_EMAIL \
  --network host \
  --ulimit nofile=1000000 \
  fullnode/filecoin-saturn-l1-node:$SATURN_NETWORK
  # ghcr.io/filecoin-saturn/l1-node:$SATURN_NETWORK
INFO "docker ps | grep saturn-node"
docker ps | grep saturn-node
