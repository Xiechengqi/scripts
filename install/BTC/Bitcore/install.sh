#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/23
# compile install bitcore (https://github.com/bitpay/bitcore)
#

source /etc/profile

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
# environment
serviceName="bitcore"
version="8.25.12"
installPath="/data/BTC/${serviceName}-${version}"
downloadUrl="https://github.com/bitpay/bitcore/archive/refs/tags/v${version}.tar.gz"
user="bitcore"   # 启动 bitcore 用户
rpcPort="18332"  # bitcoin 配置
p2pPort="18333"   # bitcoin 配置
rpcPassword="local321"   # bitcoin 配置
rpcUser="bitcore"    # bitcoin 配置

# install script url
bitcoinUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/BTC/Bitcoin/install.sh"
mongodbUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Mongodb/install.sh"
nodeUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Node/install.sh"
pythonUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Python/install.sh"

# install bitcoin
curl -SsL $bitcoinUrl | bash -s testnet

# install mongodb
curl -SsL $mongodbUrl | bash

# install node
curl -SsL $nodeUrl | bash

# install python
curl -SsL $pythonUrl | bash -s 3.5

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
cat > $installPath/${serviceName}.config.json << EOF
{
  "bitcoreNode": {
    "chains": {
      "BTC": {
        "testnet": {
          "chainSource": "p2p",
          "trustedPeers": [
            {
              "host": "127.0.0.1",
              "port": $p2pPort 
            }
          ],
          "rpc": {
            "host": "127.0.0.1",
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

[Service]
User=bitcore
Group=bitcore
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
EXEC "systemctl daemon-reload && systemctl enable --now $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "version: $version"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/${serviceName}.config.json"
YELLOW "log path: $installPath/logs"
YELLOW "rpcUser: $rpcUser"
YELLOW "rpcPassword: $rpcPassword"
YELLOW "rpcPort: $rpcPort"
YELLOW "p2pPort: $p2pPort"
YELLOW "connection cmd: "
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main
