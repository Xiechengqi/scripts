#!/usr/bin/env bash

#
# 2022/10/29
# xiechengqi
# filecoin-saturn-l1-node setup
# https://raw.githubusercontent.com/filecoin-saturn/L1-node/main/run.sh
#

source /etc/profile
# BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

# install docker
docker images || curl -SsL ${BASEURL}/install/Docker/install.sh | sudo bash -s verison

# install ooklaserver
systemctl is-active ooklaserver || curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/ooklaserver/install.sh | sudo bash

export FIL_WALLET_ADDRESS=${2-"f1no34za7ekr6vzdtylz4nci2avdoyg3nw2c3gfzy"}
export NODE_OPERATOR_EMAIL=${3-"onealemail@163.com"}
export SATURN_NETWORK="main"
export SATURN_HOME="/data/filecoin-saturn-l1-node"
EXEC "mkdir -p ${SATURN_HOME}"
region=${1}
[ ".${region}" = "." ] && echo "Empty region code, choose Singapore|VA|OH|OR|Mumbai|Stockholm|Seoul|Dublin|Tokyo" && exit 1
image="fullnode/filecoin-saturn-l1-node:${region}"

INFO "Running Saturn $SATURN_NETWORK network L1 Node on $SATURN_HOME"
EXEC "docker rm -f saturn-node || true"
INFO "Add hosts"
sed -i '/^# Server/d;/^127.0.0.1/d' /etc/hosts
cat >> /etc/hosts << EOF
127.0.0.1 localhost
# Server: KamaTera, Inc. - IL (id: 11616)
127.0.0.1 fibertest.bezeq.co.il
# Server: Axione - Paris(id: 28308)
127.0.0.1 speedperf.axione.fr speedperf.axione.fr.prod.hosts.ooklaserver.net
# Server: Swish Fibre - London(id: 34948)
127.0.0.1 speedtest.swishfibre.com speedtest.swishfibre.com.prod.hosts.ooklaserver.net
# Server: Vodafone Portugal - Lisboa(id: 46985)
127.0.0.1 speedtest-alfr.vodafone.pt speedtest-alfr.vodafone.pt.prod.hosts.ooklaserver.net
# Server: T BROS Ltd - Bulgaria(id: 37980)
127.0.0.1 speedtest.tbros.net
# Server: InNET - Kuala Lumpur (id: 20140)
127.0.0.1 speed.innet.com.my speed.innet.com.my.prod.hosts.ooklaserver.net
# Server: Claro Colombia - Bogotá (id: 44095)
127.0.0.1 speedtestbog01.claro.net.co speedtestbog01.claro.net.co.prod.hosts.ooklaserver.net
# Server: Metrotel - Buenos Aires (id: 18908)
127.0.0.1 speedtest2.metrotel.com.ar
# Server: Mobily - Saudi Arabia (id: 1733)
127.0.0.1 jed.myspeed.net.sa jed.myspeed.net.sa.prod.hosts.ooklaserver.net
# Server: Cambodia - Phnom Penh (id: 5828)
127.0.0.1 speedtest.sinet.com.kh speedtest.sinet.com.kh.prod.hosts.ooklaserver.net
# Server: HOSTMEIN IKE - Greece (id: 15410)
127.0.0.1 ookla.hostmein.net ookla.hostmein.net.prod.hosts.ooklaserver.net
# Server: Vodafone Egypt - Cairo (id: 34283)
127.0.0.1 speedtest6.vodafone.com.eg speedtest6.vodafone.com.eg.prod.hosts.ooklaserver.net
# Server: Claro Guatemala (100G) - Guatemala (id: 40095)
127.0.0.1 speedtest100g.claro.com.gt speedtest100g.claro.com.gt.prod.hosts.ooklaserver.net
# Server: Suniway Telecom - Manila (id: 44419)
127.0.0.1 speedtestph.suniway.net
# Server: WorldLink Communications Ltd - Kathmandu (id: 46451)
127.0.0.1 speedtest2.wlink.com.np
EOF
INFO "docker run --name saturn-node -it -d --restart=unless-stopped -v $SATURN_HOME/shared:/usr/src/app/shared -e FIL_WALLET_ADDRESS=$FIL_WALLET_ADDRESS -e NODE_OPERATOR_EMAIL=$NODE_OPERATOR_EMAIL --network host --ulimit nofile=1000000 ghcr.io/filecoin-saturn/l1-node:$SATURN_NETWORK"
docker run --name saturn-node -it -d \
  --restart=unless-stopped \
  -v /root/meminfo:/proc/meminfo:rw \
  -v /root/cpuinfo:/root/cpuinfo:rw \
  -v /root/df-gb:/root/df-gb:rw \
  -v /root/df-mb:/root/df-mb:rw \
  -v $SATURN_HOME/shared:/usr/src/app/shared \
  -e FIL_WALLET_ADDRESS=$FIL_WALLET_ADDRESS \
  -e NODE_OPERATOR_EMAIL=$NODE_OPERATOR_EMAIL \
  --network host \
  --ulimit nofile=1000000 \
  ${image}
INFO "docker ps | grep saturn-node"
docker ps | grep saturn-node
