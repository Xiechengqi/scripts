#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/09
# Ubuntu 18.04
# https://github.com/ripple/rippled
# apt install ripple-node
#

source /etc/profile

OS() {
osType=$1
osVersion=$2
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/tool/os.sh | bash -s ${osType} ${osVersion} || exit 1
}

INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
}

YELLOW() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[33m%s\033[0m" "$1"
printf "\n"
}

ERROR() {
printf -- "\033[41;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
exit 1
}

EXEC() {
local cmd="$1"
INFO "${cmd}"
eval ${cmd} 1> /dev/null
if [ $? -ne 0 ]; then
ERROR "Execution command (${cmd}) failed, please check it and try again."
fi
}

main() {

# check os
OS "ubuntu" "18"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
serviceName="rippled"
installPath="/data/Ripple/${serviceName}-${net}"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{logs,data}"

# install
EXEC "apt update && apt install -y apt-transport-https ca-certificates wget gnupg"
EXEC "wget -q -O - 'https://repos.ripple.com/repos/api/gpg/key/public' |  apt-key add -"
EXEC "apt-key finger"
EXEC "echo 'deb https://repos.ripple.com/repos/rippled-deb bionic stable' | tee -a /etc/apt/sources.list.d/ripple.list"
EXEC "apt update && apt install -y rippled"

# ln conf bin
EXEC "ln -fs /opt/ripple/bin $installPath/bin"
EXEC "ln -fs /opt/ripple/etc $installPath/conf"

# conf
cat > $installPath/conf/rippled.cfg << EOF
[server]
port_rpc_admin_local
port_peer
port_ws_admin_local
[port_rpc_admin_local]
port = 5005
ip = 127.0.0.1
admin = 127.0.0.1
protocol = http
[port_peer]
port = 51235
ip = 0.0.0.0
protocol = peer
[port_ws_admin_local]
port = 6006
ip = 127.0.0.1
admin = 127.0.0.1
protocol = ws
[node_size]
medium
[node_db]
type=NuDB
path=$installPath/data/nudb
online_delete=512
advisory_delete=0
[database_path]
$installPath/data
[debug_logfile]
$installPath/${serviceName}.log
[sntp_servers]
time.windows.com
time.apple.com
time.nist.gov
pool.ntp.org
[validators_file]
validators.txt
[rpc_startup]
{ \"command\": \"log_level\", \"severity\": \"warning\" }
[ssl_verify]
1
EOF

if [ "$net" = "mainnet" ]
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
fi

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
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
