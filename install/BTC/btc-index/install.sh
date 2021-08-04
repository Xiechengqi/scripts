#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/03
# https://github.com/bitpay/bitcore
# Ubuntu 18.04
# compile install bitcore
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

# environment
serviceName="btc-index"
version="8.25.12"
installPath="/data/BTC/${serviceName}-${version}"
downloadUrl="https://github.com/bitpay/bitcore/archive/refs/tags/v${version}.tar.gz"
user="btc-index"   # 启动 bitcore 用户
hostIp="127.0.0.1" # 安装 bitcoin 主机 ip
[ "$net" = "mainnet" ] && rpcPort="8332" || rpcPort="18332"  # 同 bitcoin 配置
[ "$net" = "mainnet" ] && p2pPort="8333" || p2pPort="18333"  # 同 bitcoin 配置
rpcUser="bitcoin"    # 同 bitcoin 配置
rpcPassword="local321"   # 同 bitcoin 配置

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# install script url
mongodbUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Mongodb/install.sh"
nodeUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Node/install.sh"

# install mongodb
curl -SsL $mongodbUrl | bash

# install node
curl -SsL $nodeUrl | bash -s 12.16.0

# install gcc
gcc --version &> /dev/null || EXEC "apt update && apt install -y build-essential"
EXEC "gcc --version" && gcc --version
EXEC "g++ --version" && g++ --version

# check install path
[ ! -d $installPath ] && EXEC "mkdir -p $installPath/logs"

# check user
! cat /etc/passwd | grep $user &> /dev/null && EXEC "useradd -m $user"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# chown
EXEC "chown -R $user:$user $installPath"

# compile and install
INFO "su $user -c 'cd $installPath && npm install'"
su $user -c "cd $installPath && npm install"

# config
cat > $installPath/bitcore.config.json << EOF        # 配置文件名不可修改
{
  "bitcoreNode": {
    "chains": {
      "BTC": {
        "$net": {
          "chainSource": "p2p",
          "trustedPeers": [
            {
              "host": "$hostIp",
              "port": $p2pPort 
            }
          ],
          "rpc": {
            "host": "$hostIp",
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

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
export NODE_OPTIONS=--max_old_space_size=3145728
cd $installPath && npm run node &> $installPath/logs/$(date +%Y%m%d%H%M%S).log
EOF
EXEC "chmod +x $installPath/start.sh"

# chown
EXEC "chown -R $user:$user $installPath"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=A full stack for bitcoin and blockchain-based applications
Documentation=https://github.com/bitpay/bitcore
After=network.target

[Service]
User=$user
Group=$user
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
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
YELLOW "config path: $installPath/bitcore.config.json"
YELLOW "log path: $installPath/logs"
YELLOW "rpcUser: $rpcUser"
YELLOW "rpcPassword: $rpcPassword"
YELLOW "rpcPort: $rpcPort"
YELLOW "p2pPort: $p2pPort"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
