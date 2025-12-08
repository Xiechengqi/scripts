#!/usr/bin/env bash
#
# xiechengqi
# 2025/08/01
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/ubuntu/ufw/add-ip.sh | sudo bash -s [ip]
#

main() {

local ip=${1}
[ ".${ip}" = "." ] && echo "Less IP, exit ..." && exit 1
echo "=> ufw allow from ${ip}"
ufw allow from ${ip}

}

main $@
