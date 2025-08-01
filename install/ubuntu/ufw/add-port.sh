#!/usr/bin/env bash
#
# xiechengqi
# 2025/08/01
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/ubuntu/ufw/add-port.sh | sudo bash -s [port]
#

main() {

local port=${1}
[ ".${port}" = "." ] && echo "Less Port, exit ..." && exit 1
echo "=> grep ufw ${port}"
ufw status numbered | grep -E "^\[[0-9]+\] ${port} " && echo "ufw have added port ${port}, exit ..." && exit 0
echo "=> add ufw ${port}"
echo "=> ufw allow ${port}"
ufw allow ${port}

}

main $@
