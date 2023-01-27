#!/usr/bin/env bash

#
# 2023/01/27
# xiechengqi
# mystnodes
# https://docs.mysterium.network/for-node-runners/docker-guide
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

EXEC "apt install -y vnstat"

# install docker
INFO "curl -SsL ${BASEURL}/install/Docker/install.sh | bash"
curl -SsL ${BASEURL}/install/Docker/install.sh | bash

dataPath="/data/myst/data" && EXEC "mkdir -p ${dataPath}"

# start
EXEC "docker pull mysteriumnetwork/myst:latest"
docker ps | grep -v grep | grep myst &> /dev/null || EXEC "docker run -itd --cap-add NET_ADMIN -p 4449:4449 -v ${dataPath}:/var/lib/mysterium-node --restart unless-stopped --name myst mysteriumnetwork/myst:latest service --agreed-terms-and-conditions"

# crontab update
EXEC "curl -SsL ${BASEURL}/install/myst/update.sh -o ${dataPath}/update.sh"
EXEC "chmod +x ${dataPath}/update.sh"
echo "00 03 * * * bash ${dataPath}/update.sh" | crontab
INFO "crontab -l" && crontab -l

INFO "curl -SsL ${BASEURL}/install/node-exporter/install.sh | sudo bash"
curl -SsL ${BASEURL}/install/node-exporter/install.sh | sudo bash
