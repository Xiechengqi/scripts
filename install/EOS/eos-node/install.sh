#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/03
# Ubuntu 18.04
# install eos-node
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

function main() {
# check os
OS "ubuntu" "18"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
serviceName="eos-node"
version="2.1.0"
installPath="/data/EOS/${serviceName}-${version}"
downloadUrl="https://github.com/eosio/eos/releases/download/v${version}/eosio_${version}-1-ubuntu-18.04_amd64.deb"
httpPort="8888"
p2pPort="9876"
[ "$net" = "mainnet" ] && genesisFileUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/EOS/eos-node/mainnet-genesis.json" || genesisFileUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/EOS/eos-node/jungle-genesis.json"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{src,conf,data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl -o $installPath/src/${serviceName}-${version}.deb"

# download genesis.json
EXEC "curl -SsL $genesisFileUrl -o $installPath/conf/genesis.json"

# install
EXEC "apt update && apt install -y libpq5"
EXEC "dpkg -i $installPath/src/${serviceName}-${version}.deb"
EXEC "nodeos -v" && nodeos -v

# register path
EXEC "ln -fs /usr/opt/eosio/${version}/bin $installPath/bin"

# conf，config file name must be config.ini
cat > $installPath/conf/config.ini << EOF
blocks-dir = "$installPath/data"
http-server-address = 0.0.0.0:$httpPort
p2p-listen-endpoint = 0.0.0.0:$p2pPort
access-control-allow-origin = *
allowed-connection = any
max-clients = 2000
connection-cleanup-period = 30
sync-fetch-span = 2000
enable-stale-production = false
chain-state-db-size-mb = 16384
reversible-blocks-db-size-mb = 2048
http-validate-host = false
p2p-max-nodes-per-host=200
chain-threads = 8
http-threads = 6
http-max-response-time-ms = 60000
abi-serializer-max-time-ms = 50000

plugin = eosio::chain_plugin
plugin = eosio::chain_api_plugin
plugin = eosio::http_plugin
plugin = eosio::history_api_plugin

EOF

if [ "$net" = "mainnet" ]
then
## mainnet p2p-peer-address，https://eosnodes.privex.io/?config=1
cat >> $installPath/conf/config.ini << EOF
# https://eosnodes.privex.io/?config=1
p2p-peer-address = api-full1.eoseoul.io:9876
p2p-peer-address = api-full2.eoseoul.io:9876
p2p-peer-address = bp.cryptolions.io:9876
p2p-peer-address = br.eosrio.io:9876
p2p-peer-address = eos-seed-de.privex.io:9876
p2p-peer-address = eu1.eosdac.io:49876
p2p-peer-address = fn001.eossv.org:443
p2p-peer-address = fullnode.eoslaomao.com:443
p2p-peer-address = mainnet.eoscalgary.io:5222
p2p-peer-address = node1.eoscannon.io:59876
p2p-peer-address = p2p.eosdetroit.io:3018
p2p-peer-address = p2p.genereos.io:9876
p2p-peer-address = peer.eosn.io:9876
p2p-peer-address = peer.main.alohaeos.com:9876
p2p-peer-address = peer1.mainnet.helloeos.com.cn:80
p2p-peer-address = peer2.mainnet.helloeos.com.cn:80
p2p-peer-address = publicnode.cypherglass.com:9876
EOF

else

## testnet p2p-peer-address，http://monitor3.jungletestnet.io/#p2p
cat >> $installPath/conf/config.ini << EOF
# http://monitor3.jungletestnet.io/#p2p
p2p-peer-address = jungle3.cryptolions.io:9877
p2p-peer-address = jungle.eosn.io:9876
p2p-peer-address = peer1-jungle.eosphere.io:9876
p2p-peer-address = jungle3.eossweden.org:59073
p2p-peer-address = peer.jungle3.alohaeos.com:9876
p2p-peer-address = p2p-jungle.eoasrabia.net:9876
p2p-peer-address = peer-junglenet.nodeone.network:9873
p2p-peer-address = jungle2.cryptolions.io:9876
p2p-peer-address = 54.206.215.92:9876
p2p-peer-address = 116.203.76.160:1111
EOF

fi

# create start.sh
[ "$net" = "mainnet" ] && options="" || options="--testnet"
cat > $installPath/start.sh << EOF
#!/usr/bin/env /bash
source /etc/profile

[ \$(ls $installPath/data/\$* | wc -w) = "0" ] && genesisOptions="--genesis-json $installPath/conf/genesis.json --delete-all-blocks" || genesisOptions=""
nodeos \$genesisOptions --config-dir $installPath/conf --data-dir $installPath/data  &> $installPath/logs/\$(date +%Y%m%d%H%M%S).log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=EOS
Documentation=https://github.com/EOSIO/eos
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=pkill nodeos
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "version: $version"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "log path: $installPath/logs"
YELLOW "data path: $installPath/data"
YELLOW "blockchain info cmd: cleos get info"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
