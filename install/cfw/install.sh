#!/usr/bin/env bash

#
# xiechengqi
# 2024/03/03
# Ubuntu 20.04+
# install cfw
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
# BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu20+"

serviceName="cfw"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# install
EXEC "curl https://raw.githubusercontent.com/Cyberbolt/cfw/main/install.py | python3"

# check
source ~/.bashrc
INFO "systemctl status --no-pager ${serviceName}" && systemctl status --no-pager ${serviceName}

EXEC "sleep 5"

# open 443 80
EXEC "/etc/cfw/py39/bin/python /etc/cfw/client.py allow 80"
EXEC "/etc/cfw/py39/bin/python /etc/cfw/client.py allow 443"
INFO "/etc/cfw/py39/bin/python /etc/cfw/client.py status" && /etc/cfw/py39/bin/python /etc/cfw/client.py status

}

main $@
