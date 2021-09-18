#!/usr/bin/env bash

#
# xiechengqi
# 2021/09/18
# Ubuntu 18+
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
serviceName="ripple-node"
installPath="/data/Ripple/${serviceName}-stable"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{conf,data,logs}"

# install
EXEC "apt update && apt install -y apt-transport-https ca-certificates wget gnupg"
EXEC "wget -q -O - 'https://repos.ripple.com/repos/api/gpg/key/public' |  apt-key add -"
EXEC "apt-key finger"
EXEC "echo 'deb https://repos.ripple.com/repos/rippled-deb bionic stable' > /etc/apt/sources.list.d/ripple.list"
EXEC "apt update && apt install --reinstall -y rippled" 
EXEC "mv /opt/ripple/bin $installPath/bin"

# uninstall default apt installed rippled
EXEC "systemctl stop rippled && apt purge -y rippled"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin"

# conf
## https://xrpl.org/connect-your-rippled-to-the-xrp-test-net.html
cat > $installPath/conf/rippled.cfg << EOF
[server]
port_rpc_admin_local
port_peer
port_ws_admin_local
[port_rpc_admin_local]
port = 5005
ip = 0.0.0.0
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
$installPath/logs/debug.log
[sntp_servers]
time.windows.com
time.apple.com
time.nist.gov
pool.ntp.org
[validators_file]
validators.txt
[rpc_startup]
{ "command": "log_level", "severity": "warning" }
[ssl_verify]
1
EOF

if [ "$chainId" = "mainnet" ]
then
cat > $installPath/conf/validators.txt << EOF
[validator_list_sites]
https://vl.ripple.com
[validator_list_keys]
ED2677ABFFD1B33AC6FBC3062B71F1E8397C1505E1C42C64D11AD1B28FF73F4734
EOF
else
cat > $installPath/conf/validators.txt << EOF
[validator_list_sites]
https://vl.altnet.rippletest.net
[validator_list_keys]
ED264807102805220DA0F312E71FC2C69E1552C9C5790F6C25E3729DEB573D5860
EOF
cat >> $installPath/conf/rippled.cfg << EOF
[ips]
r.altnet.rippletest.net 51235
EOF
fi

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Ripple Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/rippled --net --silent --conf /data/Ripple/ripple-node/conf/rippled.cfg
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs $installPath/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl restart $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} chain: ${chainId}"
YELLOW "install: $installPath"
YELLOW "config: $installPath/conf"
YELLOW "log: $installPath/logs"
YELLOW "data: $installPath/data"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"

}

main $@
