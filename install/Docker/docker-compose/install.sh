#!/usr/bin/env bash

#
# 2021/08/09
# xiechengqi
# install docker-compose
#

source /etc/profile
# BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|centos7|centos8' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

version=${1-"1.29.2"}
countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`
[ "$countryCode" = "CN" ] && downloadUrl="https://get.daocloud.io/docker/compose/releases/download/${version}/docker-compose-`uname -s`-`uname -m`" || downloadUrl="https://github.com/docker/compose/releases/download/${version}/docker-compose-`uname -s`-`uname -m`"

# check service
docker-compose version &> /dev/null && YELLOW "docker-compose has been installed ..." && return 0

# download
EXEC "curl -SsL $downloadUrl > /usr/bin/docker-compose"

# register bin
EXEC "chmod +x /usr/bin/docker-compose"

# info
EXEC "docker-compose version" && docker-compose version
}

main $@
