#!/usr/bin/env bash
#
# 2025/08/23
# xiechengqi
# install rage4
# usage: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rage4/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

if ! grep RAGE_ANYCAST_EMAIL env || ! grep RAGE_ANYCAST_NETWORK env || ! grep REGION env || ! grep RAGE_ANYCAST_APIKEY env || ! grep ANYCAST_IP_LIST env || ! grep RAGE_ANYCAST_NETWORK_PASSWORD env
then
cat << EOF
export RAGE_ANYCAST_EMAIL=
export RAGE_ANYCAST_NETWORK=
export REGION=
export RAGE_ANYCAST_APIKEY=
# ANYCASTIP1,ANYCASTIP2...
export ANYCAST_IP_LIST=
export RAGE_ANYCAST_NETWORK_PASSWORD=
EOF
ERROR "Create env file contains above env ..."
fi

source ./env
cat << EOF
REGION: ${REGION}
RAGE_ANYCAST_APIKEY: ${RAGE_ANYCAST_APIKEY}
ANYCAST_IP_LIST: ${ANYCAST_IP_LIST}
RAGE_ANYCAST_NETWORK_PASSWORD: ${RAGE_ANYCAST_NETWORK_PASSWORD}
EOF

YELLOW "curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rage4/install-zerotier.sh | bash -s ${REGION} ${RAGE_ANYCAST_APIKEY} ${ANYCAST_IP_LIST}"
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rage4/install-zerotier.sh | bash -s ${REGION} ${RAGE_ANYCAST_APIKEY} ${ANYCAST_IP_LIST} || exit 1

YELLOW "curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rage4/install-bird.sh | bash -s ${REGION} ${RAGE_ANYCAST_NETWORK_PASSWORD}"
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rage4/install-bird.sh | bash -s ${REGION} ${RAGE_ANYCAST_NETWORK_PASSWORD}

}

main $@
