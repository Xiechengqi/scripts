#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/11
# https://github.com/qtumproject/qtuminfo
# https://github.com/qtumproject/qtuminfo-api
# https://github.com/qtumproject/qtuminfo-ui
# Ubuntu 18.04
# https://github.com/qtumproject/qtuminfo/blob/master/doc/deploy.md
# install qtum index
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

function install_qtuminfo() {

# environments
local serviceName="qtuminfo"
local installPath="/data/Qtum/qtum-index/${serviceName}"
local downloadUrl="https://github.com/qtumproject/qtuminfo.git"
local initSqlUrl="https://raw.githubusercontent.com/qtumproject/qtuminfo/master/doc/structure.sql"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# download
EXEC "rm -rf $installPath"
EXEC "git clone -b master $downloadUrl $installPath" 
EXEC "mkdir $installPath/logs"

# install
EXEC "cd $installPath && npm install"

# Edit file qtuminfo-node.json and change the configurations if needed
cat > $installPath/qtuminfo-node.json << EOF
{
  "version": "0.0.1",
  "chain": "$chainId",
  "services": [
    "db",
    "p2p",
    "header",
    "block",
    "transaction",
    "contract",
    "mempool",
    "server"
  ],
  "servicesConfig": {
    "db": {
      "mysql": {
        "uri": "mysql://${dbUser}:${dbPassword}@${dbHost}/${dbName}"
      },
      "rpc": {
        "protocol": "http",
        "host": "localhost",
        "port": $rpcPort,
        "user": "$rpcUser",
        "password": "$rpcPassword"
      }
    },
    "p2p": {
      "peers": [
        {
          "ip": {
            "v4": "127.0.0.1"
          },
          "port": $p2pPort 
        }
      ]
    },
    "server": {
      "port": $serverPort 
    }
  }
}
EOF

# Create database and import structure.sql
EXEC "mysql -u${dbUser} -p${dbPassword} -e 'CREATE DATABASE ${dbName};'"
EXEC "curl -SsL $initSqlUrl -o $installPath/structure.sql"
EXEC "mysql -u${dbUser} -p${dbPassword} $dbName < $installPath/structure.sql"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log
cd $installPath && npm run dev &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=qtum index
Documentation=https://github.com/qtumproject/qtuminfo
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

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "$serviceName is running ..."
}

function install_qtuminfo-api() {
# environments
local serviceName="qtuminfo-api"
local installPath="/data/Qtum/qtum-index/${serviceName}"
local downloadUrl="https://github.com/qtumproject/qtuminfo-api.git"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# download
EXEC "rm -rf $installPath"
EXEC "git clone -b master $downloadUrl $installPath"
EXEC "mkdir -p $installPath/{config,logs}"

# install
EXEC "cd $installPath && npm install"

# conf
cat > $installPath/config/config.prod.js << EOF
const path = require('path')
const Redis = require('ioredis')

const redisConfig = {
  host: '$redisHost',
  port: $redisPort,
  password: '$redisPassword',
  db: 0
}

exports.keys = 'qtuminfo-api'

exports.security = {
  csrf: {enable: false}
}

// exports.middleware = ['ratelimit']
exports.middleware = []

exports.redis = {
  client: redisConfig}

exports.ratelimit = {
  db: new Redis(redisConfig),
  headers: {
    remaining: 'Rate-Limit-Remaining',
    reset: 'Rate-Limit-Reset',
    total: 'Rate-Limit-Total',
  },
  disableHeader: false,
  errorMessage: 'Rate Limit Exceeded',
  duration: 10 * 60 * 1000,
  max: 10 * 60
}

exports.io = {
  redis: {
    ...redisConfig,
    key: 'qtuminfo-api-socket.io'
  },
  namespace: {
    '/': {connectionMiddleware: ['connection']}
  }
}

exports.sequelize = {
  dialect: 'mysql',
  database: 'qtum_$chainId',
  host: '$dbHost',
  port: $dbPort,
  username: '$dbUser',
  password: '$dbPassword'
}

exports.qtum = {
  chain: '$chainId'
}

exports.qtuminfo = {
  path: path.resolve('..', 'qtuminfo'),
  port: $serverPort,
  rpc: {
    protocol: 'http',
    host: 'localhost',
    port: $rpcPort,
    user: '$rpcUser',
    password: '$rpcPassword'
  }
}

exports.cmcAPIKey = null
EOF
EXEC "sed -i 's/--daemon//' $installPath/package.json"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log
cd $installPath && npm start &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=qtum index
Documentation=https://github.com/qtumproject/qtuminfo
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

# info
YELLOW "$serviceName is running ..."
}

function install_qtuminfo-ui() {
# environments
local serviceName="qtuminfo-ui"
local installPath="/data/Qtum/qtum-index/${serviceName}"
local downloadUrl="https://github.com/qtumproject/qtuminfo-ui.git"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# download
EXEC "rm -rf $installPath"
EXEC "git clone -b master $downloadUrl $installPath"
EXEC "mkdir -p $installPath/logs"

# install
EXEC "cd $installPath && npm install"


}

main() {

# check os
OS "ubuntu" "18"

# get net option
[ "$1" = "mainnet" ] && net="mainnet" || net="testnet"

# environments
local installPath="/data/Qtum/qtum-index"
local dbHost="localhost"
local dbPort="3306"
local dbUser="root"
local dbPassword="P@ssword"
local rpcUser="user"
local rpcPassword="password"
local serverPort="3001"
if [ "$net" = "mainnet" ]
then
local chainId="mainnet"
local dbName="qtum_$chainId"
local rpcPort="3889"
local p2pPort="3888"
else
local chainId="testnet"
local dbName="qtum_$chainId"
local rpcPort="13889"
local p2pPort="13888"
fi
local redisHost="localhost"
local redisPort="6397"
local redisPassword="P@ssword"


# install script url
nodeUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Node/install.sh"
redisUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Redis/install.sh"
mysqlUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Mysql/install.sh"

# check install path
EXEC "mkdir -p $installPath"

# install node 12.16.0
curl -SsL $nodeUrl | bash -s 12.16.0

# install redis 5.0.3
curl -SsL $redisUrl | bash -s 5.0.3

# install mysql 8.0
curl -SsL $mysqlUrl | bash -s 8.0

# install qtuminfo
install_qtuminfo

# install qtuminfo-api
install_qtuminfo-api

}

main $@
