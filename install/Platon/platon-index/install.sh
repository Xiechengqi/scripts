#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/29
# gitlab: https://github.com/Xiechengqi/wx-platon-indexer.git
# os: ubuntu 18+
# make install platon index
# prerequisites
#   platon node
#   Python 3.6
#   Postgresql 10.5 (https://github.com/postgres/postgres)
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

# environments
local serviceName="platon-index"
local version="20210729"
local installPath="/data/Platon/${serviceName}-${version}"
local downloadUrl="https://github.com/Xiechengqi/wx-platon-indexer/archive/refs/tags/${version}.tar.gz"
local nodeHost="47.241.98.219"
local startBlockNumber="214799"
local rpcPort="6789"
local user="postgres"
local dbName="platon"
local dbUser="platon"
local dbPassword="platon"

# install scripts url
postgresUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Postgres/install.sh"

# check service
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
create database $dbName;
EOF
EXEC "su $user -c 'psql -f /home/$user/create.sql'"
EXEC "su $user -c 'psql -f $installPath/create_table.sql $dbName'"
cat > /home/$user/init.sql << EOF
create user $dbUser with password '$dbPassword';
GRANT ALL ON platontxs TO $dbUser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $dbUser;
EOF
EXEC "su $user -c 'psql -f /home/$user/init.sql $dbName'"

# install python modules
! pipe3 --version &>/dev/null && EXEC "export DEBIAN_FRONTEND=noninteractive" && EXEC "apt update && apt install -y python3-pip"
pip3 list --format=legacy | grep web3 &>/dev/null && EXEC "pip3 -y uninstall pip3"
EXEC "pip3 install web3==4.9.0"
EXEC "pip3 install psycopg2"

# install client-sdb-python
EXEC "rm -rf /tmp/client-sdk-python"
EXEC "git clone https://github.com/PlatONnetwork/client-sdk-python.git /tmp/client-sdk-python"
EXEC "cd /tmp/client-sdk-python"
EXEC "pip3 install ."
EXEC "cd -"

# config
cat > $installPath/config.ini << EOF
[base]
node_address = http://${nodeHost}:${rpcPort}
log_file_path = $installPath/logs/platon-index.log
start_block_number = ${startBlockNumber}

[db]
host = 127.0.0.1
user = $dbUser 
password = $dbPassword
EOF

# create start.sh
pythonPath=$(which python3.6)
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash

source /etc/profile
cd $installPath 
$pythonPath $installPath/platonsync.py $dbName
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
TimeoutSec=300
RestartSec=90
Restart=always

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
YELLOW "config path: $installPath/config.ini"
YELLOW "log path: $installPath/logs"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main