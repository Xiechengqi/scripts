#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/19
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
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install_geth() {

# environments
version="1.10.5-33ca98ec"
installPath="/data/ETH/geth-${version}"
downloadUrl="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-${version}.tar.gz"
wsport="8544"
serviceName="eth"

# check
systemctl is-active $serviceName &> /dev/null && INFO "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{data,logs}"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register bin
EXEC "ln -fs $installPath/geth /usr/bin/geth"
EXEC "geth version"

# create start.sh
pubIp=`curl -4 ip.sb`
cat > $installPath/start.sh << EOF
$installPath/geth --nat=extip:$pubIp --http --http.addr 0.0.0.0 --ws --ws.addr 0.0.0.0 --ws.port $wsport --datadir $installPath/data --http.vhosts=* &> $installPath/logs/geth.log
EOF
chmod +x $installPath/start.sh

# register serivce
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Official Go implementation of the Ethereum protocol
Documentation=https://github.com/ethereum/go-ethereum

[Service]
User=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# start
EXEC "systemctl daemon-reload && systemctl enable --now $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

}

function install_pyenv() {
# check
pyenv -v &> /dev/null && INFO "pyenv -v" && pyenv -v && return 0

# install pyenv
EXEC "curl https://pyenv.run | bash"

# register path
echo 'export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"' >> /etc/profile
EXEC "ln -fs /root/.pyenv/bin/pyenv /usr/bin/pyenv"
EXEC "source /etc/profile"
EXEC "pyenv -v"
pyenv -v
}

function install_python() {
# check
python3.6 --version &>/dev/null && INFO "python3.6 --version" && python3.6 --version && return 0

# environments
local version="3.6.9"

# install gcc/make/zlib
EXEC "apt update && apt install -y build-essential zlib1g-dev libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev liblzma-dev"

# install python3.6
EXEC "pyenv install -v $version"

# link
EXEC "ln -fs /root/.pyenv/versions/$version/bin/python3.6 /usr/bin/python3.6"
EXEC "ln -fs /root/.pyenv/versions/$version/bin/pip3 /usr/bin/pip3"
EXEC "python3.6 --version"
EXEC "pip3 --version"
}

function install_postgres() {

# environments
local version="10.5"
local installPath="/data/postgres-${version}"
local downloadUrl="https://get.enterprisedb.com/postgresql/postgresql-${version}-1-linux-x64-binaries.tar.gz"
local user="postgres"
local port="5432"
local serviceName="postgres"

# check
systemctl is-active $serviceName &> /dev/null && INFO "$serviceName is running ..." && return 0

# check user
! cat /etc/passwd | grep $user &> /dev/null && EXEC "useradd -m $user"

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{data,logs} && cd $installPath"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "sed -i '/postgres\/bin/d' /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
EXEC "echo 'export LD_LIBRARY_PATH=$installPath/lib' >> /etc/profile"
EXEC "ln -fs $installPath/bin/* /usr/bin/"
EXEC "source /etc/profile"
EXEC "psql --version" && psql --version

# chown
EXEC "chown -R $user.$user $installPath" 

# init db
EXEC "su $user -c '$installPath/bin/initdb -E UTF8 --locale=en_US.utf8 -D $installPath/data'"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=PostgreSQL database server
After=network.target

[Service]
Type=forking
User=$user
Group=$user
Environment=PGPORT=$port
Environment=PGDATA=$installPath/data/
Environment=PGLOG=$installPath/logs/postgres.log
OOMScoreAdjust=-1000
ExecStart=$installPath/bin/pg_ctl start -l \${PGLOG} -D \${PGDATA} -s -o "-p \${PGPORT}" -w -t 300
ExecStop=$installPath/bin/pg_ctl stop -D \${PGDATA} -s -m fast
ExecReload=$installPath/bin/pg_ctl reload -D \${PGDATA} -s
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF

# start
EXEC "systemctl daemon-reload && systemctl enable --now $serviceName"
EXEC "systemctl status postgres --no-pager" && systemctl status postgres --no-pager
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
systemctl is-active $serviceName &> /dev/null && INFO "$serviceName is running ..." && return 0 

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
EXEC "systemctl daemon-reload && systemctl enable --now $serviceName"
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

# check
systemctl is-active $serviceName &> /dev/null && INFO "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/logs"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# install postgres
INFO "install postgres ..."
install_postgres

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
INFO "install postgrest ..."
install_postgrest

# install pyenv
INFO "install pyenv ..."
install_pyenv
# install python3.6
INFO "install python3.6 ..."
install_python

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

# start
EXEC "systemctl daemon-reload && systemctl enable --now $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager
}

function main() {
INFO "install geth ..."
install_geth
INFO "install eth-indexer ..."
install_eth-indexer
}

main
