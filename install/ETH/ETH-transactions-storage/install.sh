#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/25
# os: ubuntu16.04
# make install ETH indexer
# prerequisites
#   geth or openethereum (with currently synchronized chain)
#   Python 3.6
#   Postgresql 10.5 (https://github.com/postgres/postgres)
#   Postgrest for API (https://github.com/PostgREST/postgrest)
#   nginx or other web server (in case of public API)
# https://github.com/Adamant-im/ETH-transactions-storage
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

function install_postgrest() {

# environments
local version="7.0.1"
local installPath="/data/postgrest-${version}"
local downloadUrl="https://github.com/PostgREST/postgrest/releases/download/v${version}/postgrest-v${version}-linux-x64-static.tar.xz"
local port="3000"
local postgresPort="5432"
local serviceName="postgrest"

# check
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{conf,logs}"

# download tarball
EXEC "curl -SsL $downloadUrl | xz -d > /tmp/$$.tar"
EXEC "tar xf /tmp/$$.tar -C $installPath"

# register bin
EXEC "ln -fs $installPath/* /usr/bin/"
EXEC "which postgrest"

# conf
cat > $installPath/conf/postgrest.conf << EOF
db-uri = "postgres://$dbUser:$dbPassword@127.0.0.1:$postgresPort/$dbName"
db-schema = "public"
db-anon-role = "eth"
db-pool = 10
server-host = "0.0.0.0"
server-port = $port
EOF

# create start.sh
EXEC "echo 'postgrest $installPath/conf/postgrest.conf &> $installPath/logs/postgrest.log' > $installPath/start.sh"
EXEC "chmod +x $installPath/start.sh"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Transaction API with Postgrest
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=always
RestartSec=5
StartLimitInterval=0
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager
}

function install_eth-indexer() {

# environments
local version="20210716"
local installPath="/data/ETH/eth-indexer-${version}"
local downloadUrl="https://github.com/Xiechengqi/wx-eth-indexer/archive/refs/tags/${version}.tar.gz"
local port="8545"
local user="postgres"
local dbName="eth"
local dbUser="eth"
local dbPassword="eth"
local serviceName="eth-indexer"

# install scripts url
pyenvUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Pyenv/install.sh"
pythonUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Python/install.sh"
postgresUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Postgres/install.sh"

# check
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/logs"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# install postgres
curl -SsL $postgresUrl | bash

# init pgsql
cat > /home/$user/create.sql << EOF
create database index;
create database $dbName;
EOF
EXEC "su $user -c 'psql -f /home/$user/create.sql'"
EXEC "su $user -c 'psql -f $installPath/create_table.sql $dbName'"
cat > /home/$user/init.sql << EOF
create user $dbUser with password '$dbPassword';
GRANT ALL ON ethtxs TO $dbUser;
GRANT ALL PRIVILEGES ON DATABASE index TO $dbUser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $dbUser;
EOF
EXEC "su $user -c 'psql -f /home/$user/init.sql $dbName'"

# install postgrest
install_postgrest

# install pyenv
curl -SsL $pyenvUrl | bash

# install python3.6
curl -SsL $pythonUrl | bash -s 3.6

# install python modules
EXEC "pip3 install web3"
EXEC "pip3 install psycopg2"

# config
cat > $installPath/config.ini << EOF
[base]
node_address = http://127.0.0.1:$port
log_file_path = $installPath/logs/eth-indexer.log
start_block_number = 6520000

[db]
host = 127.0.0.1
user = $dbUser 
password = $dbPassword
EOF

# register service
pythonPath=$(which python3.6)
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=EthereumTransactionStorage
After=syslog.target
After=network.target
After=postgres.service

[Service]
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
TimeoutSec=300
RestartSec=90
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# create start.sh
cat > $installPath/start.sh << EOF
source /etc/profile
cd $installPath 
$pythonPath $installPath/ethsync.py $dbName
EOF
EXEC "chmod +x $installPath/start.sh"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager
}

function main() {
INFO "install eth-indexer ..."
install_eth-indexer
}

main
