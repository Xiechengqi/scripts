#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/23
# github: https://github.com/Adamant-im/ETH-transactions-storage
# OS: ubuntu 18.04
# install ETH index
# prerequisites
#   geth or openethereum (with currently synchronized chain)
#   Python 3.6
#   Postgresql 10.5 (https://github.com/postgres/postgres)
#   Postgrest for API (https://github.com/PostgREST/postgrest)
#

source /etc/profile

trap "_clean" EXIT

_clean() {
cd /tmp && rm -f $$.tar
}

BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install_postgrest() {
# environments
local serviceName="postgrest"
local version="7.0.1"
local installPath="/data/${serviceName}-${version}"
local downloadUrl="https://github.com/PostgREST/postgrest/releases/download/v${version}/postgrest-v${version}-linux-x64-static.tar.xz"
local port="3000"
local postgresPort="5432"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
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
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile
export LD_LIBRARY_PATH=/data/postgres/lib

installPath="${installPath}"
timestamp=\$(date +%Y%m%d%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
postgrest \$installPath/conf/postgrest.conf &> \$installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Transaction API with Postgrest
After=network.target
After=postgres.target

[Service]
User=root
Group=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT $MAINPID
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
YELLOW "$serviceName is running ..."
}

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# get chainId
chainId="$1" && INFO "chain: $chainId"                                                                                                
! echo "$chainId" | grep -E 'mainnet|testnet' &> /dev/null && ERROR "You could only choose chain: mainnet、testnet"

# environments
local serviceName="eth-index"
local version="master"
local installPath="/data/ETH/${serviceName}-${version}"
local downloadUrl="https://github.com/Xiechengqi/wx-eth-indexer.git"
local nodeIp="127.0.0.1"
local port="8545"
local user="postgres"
local dbIp="127.0.0.1"
local dbName="eth"
local dbUser="eth"
local dbPassword="eth"
local startBlockNumber="6520000"

# install scripts url
postgresUrl="$BASEURL/install/Postgres/install.sh"

# check
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/logs"

# download
EXEC "git clone -b master $downloadUrl $installPath/src"

# install postgres
curl -SsL $postgresUrl | bash

# init pgsql
cat > /home/$user/create.sql << EOF
create database index;
create database $dbName;
EOF
EXEC "su $user -c 'psql -f /home/$user/create.sql'"
EXEC "su $user -c 'psql -f $installPath/src/create_table.sql $dbName'"
cat > /home/$user/init.sql << EOF
create user $dbUser with password '$dbPassword';
GRANT ALL ON ethtxs TO $dbUser;
GRANT ALL PRIVILEGES ON DATABASE index TO $dbUser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $dbUser;
EOF
EXEC "su $user -c 'psql -f /home/$user/init.sql $dbName'"

# install postgrest
install_postgrest

# install pip3
! pip3 --version &>/dev/null && EXEC "export DEBIAN_FRONTEND=noninteractive" && EXEC "apt update && apt install -y python3-pip"

# install virtualenv
EXEC "pip3 install virtualenv"

# create python venv
EXEC "virtualenv --clear $installPath/venv"

# active python venv
EXEC "source $installPath/venv/bin/activate"

# install web3 psycopg2
EXEC "pip3 install web3"
EXEC "pip3 install psycopg2"

# deactive python venv
EXEC "deactivate"

# config
cat > $installPath/src/config.ini << EOF
[base]
node_address = http://$nodeIp:$port
log_file_path = $installPath/logs/${serviceName}.log
start_block_number = $startBlockNumber 

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
python3 $installPath/src/ethsync.py $dbName
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=EthereumTransactionStorage
After=syslog.target
After=network.target
After=postgres.service
After=postgrest.service

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
YELLOW "${serviceName} version: ${version}"
YELLOW "port: ${port}"
YELLOW "install: ${installPath}"
YELLOW "conf: ${installPath}/src/config.ini"
YELLOW "log: tail -f ${installPath}/logs/${serviceName}.log"
YELLOW "check cmd: "
YELLOW "control cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
