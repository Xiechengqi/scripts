#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/23
# https://github.com/bitpay/bitcore
# Ubuntu 18+
# compile install BTC Index
# refer: https://github.com/bitpay/bitcore/blob/master/Dockerfile
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

# environment
serviceName="btc-index"
version="8.25.17"
installPath="/data/BTC/${serviceName}-${version}"
downloadUrl="https://github.com/bitpay/bitcore/archive/refs/tags/v${version}.tar.gz"
nodeIp="127.0.0.1" # 安装 bitcoin 主机 ip
[ "$chainId" = "mainnet" ] && rpcPort="8332" || rpcPort="18332"  # 同 btc-node 配置
[ "$chainId" = "mainnet" ] && p2pPort="8333" || p2pPort="18333"  # 同 btc-node 配置
rpcUser="bitcoin"    # 同 bitcoin 配置
rpcPassword="local321"   # 同 bitcoin 配置

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# install script url
mongodbUrl="$BASEURL/install/Mongodb/install.sh"
nodeUrl="$BASEURL/install/Node/install.sh"

# install mongodb
curl -SsL $mongodbUrl | bash

# install node10.24.1 and npm6.14.5
curl -SsL $nodeUrl | bash -s 10.24.1
EXEC "npm i -g npm@6.14.5"

# install gcc
EXEC "apt update && apt install -y build-essential"
EXEC "gcc --version" && gcc --version
EXEC "g++ --version" && g++ --version

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/logs"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# add key
# EXEC "curl -SsL https://dl-ssl.google.com/linux/linux_signing_key.pub -o /tmp/linux_signing_key.pub"
# EXEC "apt-key add /tmp/linux_signing_key.pub"

# install google-chrome
# EXEC "apt-get update && apt-get install -y google-chrome-stable"
# EXEC "google-chrome --version" && google-chrome --version 

# config
cat > $installPath/bitcore.config.json << EOF        # 配置文件名不可修改
{
  "bitcoreNode": {
    "chains": {
      "BTC": {
        "$chainId": {
          "chainSource": "p2p",
          "trustedPeers": [
            {
              "host": "$nodeIp",
              "port": $p2pPort 
            }
          ],
          "rpc": {
            "host": "$nodeIp",
            "port": $rpcPort,
            "username": "$rpcUser",
            "password": "$rpcPassword"
          }
        }
      }
    },
    "services": {
      "api": {
        "rateLimiter": {
          "whitelist": [
            "::ffff:127.0.0.1"
          ]
        }
      }
    }
  }
}
EOF

# compile and install
EXEC "cd $installPath"
INFO "sudo npm install" && sudo npm install || exit 1
INFO "sudo npm run bootstrap" && sudo npm run bootstrap || exit 1
INFO "sudo npm run compile" && sudo npm run compile || exit 1

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile
export NODE_OPTIONS=--max_old_space_size=3145728

installPath="$installPath"
timestamp=\$(date +%Y%m%d)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
cd \$installPath
/data/node-10.24.1/bin/npm run node &> \$installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=A full stack for bitcoin and blockchain-based applications
Documentation=https://github.com/bitpay/bitcore
After=network.target

[Service]
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
YELLOW "conf: $installPath/bitcore.config.json"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "rpcUser: $rpcUser"
YELLOW "rpcPassword: $rpcPassword"
YELLOW "rpcPort: $rpcPort"
YELLOW "p2pPort: $p2pPort"
YELLOW "control cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
