#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/26
# install Ntp
#

source /etc/profile
source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

main() {
# environment
serviceName="ntp"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# install
EXEC "apt-get update && apt-get install -y gnupg2 curl software-properties-common $serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"

# check
EXEC "ntpq -4c rv | grep leap_none" && ntpq -4c rv | grep leap_none
}

main
