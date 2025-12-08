#!/usr/bin/env bash

#
# xiechengqi
# 2021/10/09
# install cosmos-node
# https://github.com/cosmos/gaia
# mainnet install: https://hub.cosmos.network/main/gaia-tutorials/join-mainnet.html
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
! echo "$chainId" | grep -E 'mainnet' &> /dev/null && ERROR "You could only choose chain: mainnet"

serviceName="cosmos-node"
version="4.2.1"
installPath="/data/Cosmos/${serviceName}-${version}"
downloadUrl="https://github.com/cosmos/gaia/releases/download/v${version}/gaiad-v${version}-linux-amd64"
[ "$chainId" = "mainnet" ] && genesisUrl="https://github.com/cosmos/mainnet/raw/master/genesis.cosmoshub-4.json.gz" || genesisUrl=""

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,data,logs}"

# download tarball 
EXEC "curl -SsL $downloadUrl -o $installPath/bin/gaiad"

# register bin
EXEC "chmod +x $installPath/bin/*"
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "gaiad version --long" && gaiad version --long

# init 
EXEC "gaiad init ${serviceName}-${chainId} --home $installPath"

# conf
EXEC "cd $installPath/config"
EXEC "curl -SsL $genesisUrl -o genesis.cosmoshub-4.json.gz"
EXEC "gzip -d genesis.cosmoshub-4.json.gz"
EXEC "mv genesis.cosmoshub-4.json genesis.json"
EXEC "cd -"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env /bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log

gaiad start --p2p.seeds bf8328b66dceb4987e5cd94430af66045e59899f@public-seed.cosmos.vitwit.com:26656,cfd785a4224c7940e9a10f6c1ab24c343e923bec@164.68.107.188:26656,d72b3011ed46d783e369fdf8ae2055b99a1e5074@173.249.50.25:26656,ba3bacc714817218562f743178228f23678b2873@public-seed-node.cosmoshub.certus.one:26656,3c7cad4154967a294b3ba1cc752e40e8779640ad@84.201.128.115:26656,366ac852255c3ac8de17e11ae9ec814b8c68bddb@51.15.94.196:26656 --x-crisis-skip-assert-invariants --home $installPath &> \$installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/filecoin-project/lotus
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs $installPath/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "chain: ${chainId}"
YELLOW "rpc port: "
YELLOW "conf: $installPath/conf"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "control cmd: systemctl [stop|start|restart|reload] $serviceName"

}

main $@
