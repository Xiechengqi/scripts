#!/usr/bin/env bash
#
# xiechengqi
# 2025/08/01
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/ubuntu/ufw/deny-ip.sh | sudo bash -s [ip]
#

main() {

local ip=${1}
[ ".${ip}" = "." ] && echo "Less IP, exit ..." && exit 1
echo "=> ufw deny from ${ip}"
ufw deny from ${ip}

}

main $@
