#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/09
# Ubuntu 18.04
# https://github.com/ripple/rippled
# apt install ripple-node
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# get chainId
chainId="$1" && INFO "chain: $chainId"
! echo "$chainId" | grep -E 'mainnet|testnet' &> /dev/null && ERROR "You could only choose chain: mainnet、testnet"

# environments
serviceName="rippled"
installPath="/data/Ripple/${serviceName}-${net}"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath"

# install
EXEC "apt update && apt install -y apt-transport-https ca-certificates wget gnupg"
EXEC "wget -q -O - 'https://repos.ripple.com/repos/api/gpg/key/public' |  apt-key add -"
EXEC "apt-key finger"
EXEC "echo 'deb https://repos.ripple.com/repos/rippled-deb bionic stable' | tee -a /etc/apt/sources.list.d/ripple.list"
EXEC "apt update && apt install -y rippled"

# ln conf bin data logs
EXEC "ln -fs /opt/ripple/bin $installPath/bin"
EXEC "ln -fs /opt/ripple/etc $installPath/conf"
EXEC "ln -fs /var/lib/rippled/db $installPath/data"
EXEC "ln -fs /var/log/rippled $installPath/logs"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin"

# conf
if [ "$chainId" = "mainnet" ]
then

cat > /opt/ripple/etc/validators.txt << EOF
[validator_list_sites]
https://vl.ripple.com
[validator_list_keys]
ED2677ABFFD1B33AC6FBC3062B71F1E8397C1505E1C42C64D11AD1B28FF73F4734
EOF

else

cat > /opt/ripple/etc/validators.txt << EOF
[validator_list_sites]
https://vl.altnet.rippletest.net
[validator_list_keys]
ED264807102805220DA0F312E71FC2C69E1552C9C5790F6C25E3729DEB573D5860
EOF

cat >> /opt/ripple/etc/rippled.cfg << EOF
[ips]
r.altnet.rippletest.net 51235
EOF

fi

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl restart $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "log path: $installPath/logs"
YELLOW "db path: $installPath/data"
YELLOW "connection cmd: "
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"

}

main $@
