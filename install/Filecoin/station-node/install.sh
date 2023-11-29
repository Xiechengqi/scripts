#!/usr/bin/env bash

#
# xiechengqi
# 2023/11/29
# install filecoin station core
#

source /etc/profile
# BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

export FIL_WALLET_ADDRESS=${1-"0x3Cbd51c70afF7f7cDC0fa0513391f25aFA821a74"}

# install docker
INFO "install docker"
curl -SsL ${BASEPATH}/install/Docker/install.sh | sudo bash

installPath="/data/station-node"
cd ${installPath} &> /dev/null && [ "$(docker compose top | wc -l)" != "0" ] && INFO "station is running!" && docker compose top && exit 0
EXEC "rm -rf ${installPath} && mkdir -p ${installPath}"
EXEC "cd ${installPath}"
# conf
curl -SsL ${BASEURL}/install/Filecoin/station-node/docker-compose.yml | sed "s/@FIL_WALLET_ADDRESS/${FIL_WALLET_ADDRESS}/" > docker-compose.yml

# start
INFO "docker rm -f station-node station-watchtower" && docker rm -f station-node station-watchtower
INFO "docker compose up -d" && docker compose up -d && INFO "docker compose top" && docker compose top

}

main $@
