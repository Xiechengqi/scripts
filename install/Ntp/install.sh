#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/26
# install Ntp
#

function main() {
# environment
serviceName="ntp"

# install
EXEC "apt-get update && apt-get install -y gnupg2 curl software-properties-common $serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"

# check ntp
EXEC "ntpq -4c rv | grep leap_none"
}

main
