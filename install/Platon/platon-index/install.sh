#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/03
# os: ubuntu 18+
# https://github.com/HashKeyHub/platon-indexer
# make install platon index
# prerequisites
#   platon node
#   Python 3.6
#   Postgresql 10.5 (https://github.com/postgres/postgres)
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# get chainId
chainId="$1" && INFO "chain: $chainId"                                                                                                
! echo "$chainId" | grep -E 'mainnet|testnet' &> /dev/null && ERROR "You could only choose chain: mainnet、testnet"

# environments
local serviceName="platon-index"
local version="master"
local installPath="/data/Platon/${serviceName}-${version}"
local downloadUrl="https://github.com/Xiechengqi/wx-platon-indexer"
# local nodeIp="47.241.98.219"
local nodeIp="127.0.0.1"
local startBlockNumber="214799"
local rpcPort="6789"
local user="postgres"
local dbIp="127.0.0.1"
local dbName="platon"
local dbUser="platon"
local dbPassword="platon"

# install scripts url
postgresUrl="$BASEURL/install/Postgres/install.sh"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/logs"

# download tarball
EXEC "git clone -b master $downloadUrl $installPath/src"

# install postgres
curl -SsL $postgresUrl | bash

# init pgsql
cat > /home/$user/create.sql << EOF
create database $dbName;
EOF
EXEC "su $user -c 'psql -f /home/$user/create.sql'"
EXEC "su $user -c 'psql -f $installPath/src/create_table.sql $dbName'"
cat > /home/$user/init.sql << EOF
create user $dbUser with password '$dbPassword';
GRANT ALL ON platontxs TO $dbUser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $dbUser;
EOF
EXEC "su $user -c 'psql -f /home/$user/init.sql $dbName'"

# install pip3
! pip3 --version &>/dev/null && EXEC "export DEBIAN_FRONTEND=noninteractive" && EXEC "apt update && apt install -y python3-pip"

# install virtualenv
EXEC "pip3 install virtualenv"

# create python venv
EXEC "virtualenv --clear $installPath/venv"

# active python venv
EXEC "source $installPath/venv/bin/activate"

# install web3==4.9.0 psycopg2
EXEC "pip3 install web3==4.9.0"
EXEC "pip3 install psycopg2"

# install client-sdb-python
EXEC "rm -rf /tmp/client-sdk-python"
EXEC "git clone https://github.com/PlatONnetwork/client-sdk-python.git /tmp/client-sdk-python"
EXEC "cd /tmp/client-sdk-python"
EXEC "pip3 install ."
EXEC "cd -"
EXEC "pip3 list" && pip3 list

# deactive python venv
EXEC "deactivate"

# config
cat > $installPath/src/config.ini << EOF
[base]
node_address = http://${nodeIp}:${rpcPort}
log_file_path = $installPath/logs/platon-index.log
start_block_number = ${startBlockNumber}

[db]
host = $dbIp 
user = $dbUser 
password = $dbPassword
EOF

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile
export LD_LIBRARY_PATH=/data/postgres/lib

source $installPath/venv/bin/activate
cd $installPath/src
python3 $installPath/src/platonsync.py $dbName
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=platon index
After=syslog.target
After=network.target
After=postgres.service

[Service]
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
YELLOW "config path: $installPath/src/config.ini"
YELLOW "log path: $installPath/logs"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
