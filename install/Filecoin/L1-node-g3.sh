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
docker images || curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/install.sh | sudo bash -s verison

export FIL_WALLET_ADDRESS=${1-"f1no34za7ekr6vzdtylz4nci2avdoyg3nw2c3gfzy"}
EXEC "sed -i /FIL_WALLET_ADDRESS/d /etc/profile"
EXEC "echo FIL_WALLET_ADDRESS=${FIL_WALLET_ADDRESS} >> /etc/profile"
export NODE_OPERATOR_EMAIL=${2-"onealemail@163.com"}
EXEC "sed -i /NODE_OPERATOR_EMAIL/d /etc/profile"
EXEC "echo NODE_OPERATOR_EMAIL=${NODE_OPERATOR_EMAIL} >> /etc/profile"
export SPEEDTEST_SERVER_ID=${3-""}
if [ ".${SPEEDTEST_SERVER_ID}" != "." ]
then
export SPEEDTEST_SERVER_CONFIG="--server-id=${SPEEDTEST_SERVER_ID}"
EXEC "sed -i /SPEEDTEST_SERVER_CONFIG/d /etc/profile"
EXEC "echo SPEEDTEST_SERVER_CONFIG=${SPEEDTEST_SERVER_CONFIG} >> /etc/profile"
fi
export SATURN_NETWORK="main"
EXEC "sed -i /SATURN_NETWORK/d /etc/profile"
EXEC "echo SATURN_NETWORK=${SATURN_NETWORK} >> /etc/profile"
export SATURN_HOME="/data/filecoin-saturn-l1-node"
EXEC "sed -i /SATURN_HOME/d /etc/profile"
EXEC "echo SATURN_HOME=${SATURN_HOME} >> /etc/profile"
EXEC "mkdir -p ${SATURN_HOME}"

INFO "Running Saturn $SATURN_NETWORK network L1 Node on $SATURN_HOME"
EXEC "docker rm -f saturn-node || true"
image="ghcr.io/filecoin-saturn/l1-node:${SATURN_NETWORK}"
EXEC "docker pull ${image}"

INFO "docker run --name saturn-node -it -d --restart=unless-stopped -v $SATURN_HOME/shared:/usr/src/app/shared -e FIL_WALLET_ADDRESS=$FIL_WALLET_ADDRESS -e NODE_OPERATOR_EMAIL=$NODE_OPERATOR_EMAIL -e SPEEDTEST_SERVER_CONFIG=$SPEEDTEST_SERVER_CONFIG --network host --ulimit nofile=1000000 ${image}"
docker run --name saturn-node -it -d \
  --restart=unless-stopped \
  -v $SATURN_HOME/shared:/usr/src/app/shared \
  -e FIL_WALLET_ADDRESS=$FIL_WALLET_ADDRESS \
  -e NODE_OPERATOR_EMAIL=$NODE_OPERATOR_EMAIL \
  -e SPEEDTEST_SERVER_CONFIG=$SPEEDTEST_SERVER_CONFIG \
  --network host \
  --ulimit nofile=1000000 \
  ${image}
  
EXEC "curl -SsL -k https://install.xiechengqi.top/update.sh -o /root/update.sh"
EXEC "chmod +x /root/update.sh"
(crontab -l;echo "*/5 * * * * /root/update.sh >> /var/log/l1-cron.log 2>&1 ") | crontab
INFO "crontab -l" && crontab -l
  
INFO "docker ps | grep saturn-node"
docker ps | grep saturn-node
