#!/usr/bin/env bash

#
# 2022/12/05
# xiechengqi
# install supervisor on ubuntu/centos
# https://www.atlantic.net/vps-hosting/how-to-install-and-configure-supervisor-on-ubuntu-20-04/
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

_ubuntu() {

EXEC "apt update"
EXEC "apt install -y supervisor"

}

_centos() {

EXEC "yum install -y epel-release"
EXEC "yum update -y"
EXEC "yum install -y supervisor"

}

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|centos' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、centos7、centos8"

# env
if echo $osInfo | grep ubuntu &> /dev/null
then
serviceName="supervisor"
configFilePath="/etc/supervisor/supervisord.conf"
else
serviceName="supervisord"
configFilePath="/etc/supervisord.conf"
fi

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

echo $osInfo | grep ubuntu &> /dev/null && _ubuntu
echo $osInfo | grep centos &> /dev/null && _centos
INFO "supervisord -v" && supervisord -v

# config
cat >> ${configFilePath} << EOF
[inet_http_server]
port=*:9001
EOF

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl restart $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

}

main $@
