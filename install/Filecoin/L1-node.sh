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

# install ooklaserver
systemctl is-active ooklaserver || curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/ooklaserver/install.sh | sudo bash

export FIL_WALLET_ADDRESS=${2-"f1yzy2ug6ahepl6ni7iq7pdnnw2y7fxeunsfwqtyy"}
export NODE_OPERATOR_EMAIL="79834539@qq.com"
export SATURN_NETWORK="main"
export SATURN_HOME="/data/filecoin-saturn-l1-node"
EXEC "mkdir -p ${SATURN_HOME}"
region=${1}
[ ".${region}" = "." ] && echo "Empty region code, choose Singapore|VA|OH|OR|Mumbai|Stockholm|Seoul|Dublin|Tokyo" && exit 1
image="fullnode/filecoin-saturn-l1-node:${region}"

INFO "Running Saturn $SATURN_NETWORK network L1 Node on $SATURN_HOME"
EXEC "docker rm -f saturn-node || true"
INFO "Add hosts"
cat >> /etc/hosts << EOF
# Server: StarHub Ltd - Singapore (id: 4235)
127.0.0.1 co2dsvr03.speedtest.starhub.com co2dsvr03.speedtest.starhub.com.prod.hosts.ooklaserver.net
# Server: Jeebr Internet Services - Mumbai (id: 26493)
127.0.0.1 speedtest.jeebr.net
# Server: Windstream - Ashburn, VA (id: 17383)
127.0.0.1 ashburn02.speedtest.windstream.net ashburn02.speedtest.windstream.net
# Server: eero - Columbus, OH (id: 41817)
127.0.0.1 ue2a.ookla-speedtests.e2ro.com ue2a.ookla-speedtests.e2ro.com.prod.hosts.ooklaserver.net
# Server: eero - Hermiston, OR (id: 41819)
127.0.0.1 uw2a.ookla-speedtests.e2ro.com uw2a.ookla-speedtests.e2ro.com.prod.hosts.ooklaserver.net
# Server: kdatacenter.com - Seoul (id: 6527)
127.0.0.1 speedtest.kdatacenter.com speedtest.kdatacenter.com.prod.hosts.ooklaserver.net
# Server: Blacknight - Dublin (id: 4604)
127.0.0.1 speedtest1.blacknight.ie speedtest1.blacknight.ie.prod.hosts.ooklaserver.net
# Server: GSL Networks - Tokyo (id: 50686)
127.0.0.1 ty8.speedtest.gslnetworks.com ty8.speedtest.gslnetworks.com.prod.hosts.ooklaserver.net
EOF
INFO "docker run --name saturn-node -it -d --restart=unless-stopped -v $SATURN_HOME/shared:/usr/src/app/shared -e FIL_WALLET_ADDRESS=$FIL_WALLET_ADDRESS -e NODE_OPERATOR_EMAIL=$NODE_OPERATOR_EMAIL --network host --ulimit nofile=1000000 ghcr.io/filecoin-saturn/l1-node:$SATURN_NETWORK"
docker run --name saturn-node -it -d \
  --restart=unless-stopped \
  -v $SATURN_HOME/shared:/usr/src/app/shared \
  -e FIL_WALLET_ADDRESS=$FIL_WALLET_ADDRESS \
  -e NODE_OPERATOR_EMAIL=$NODE_OPERATOR_EMAIL \
  --network host \
  --ulimit nofile=1000000 \
  ${image}
INFO "docker ps | grep saturn-node"
docker ps | grep saturn-node