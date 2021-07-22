#!/usr/bin/env bash
#
# 2021/07/15
# xiechengqi
# install BTC
#

INFO() {
	printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
	printf -- "%s" "$1"
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
	eval ${cmd} 1>/dev/null
	if [ $? -ne 0 ]; then
		ERROR "Execution command (${cmd}) failed, please check it and try again."
	fi
}

function install_bitcoin() {
	# environments
	local installPath="/data/BTC/bitcoin"
	local version="0.21.1"
	local downloadUrl="https://bitcoincore.org/bin/bitcoin-core-${version}/bitcoin-${version}-x86_64-linux-gnu.tar.gz"
	local rpcPort="18332"
	local p2pPort="18333"

	# check install path
	EXEC "rm -rf $installPath"
	EXEC "mkdir -p $installPath/{data,logs}"

	# download tarball
	EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

	# register path
	EXEC "sed -i '/bitcoin/d' /etc/profile"
	EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
	EXEC "ln -fs $installPath/bin/* /usr/bin/"
	EXEC "source /etc/profile"
	INFO "bitcoin-cli -version" && bitcoin-cli -version

	# config
	cat >$installPath/bitcoin.conf <<EOF
datadir=$installPath/data
testnet=1
server=1
whitebind=127.0.0.1:$p2pPort
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubhashtx=tcp://127.0.0.1:28333
zmqpubhashblock=tcp://127.0.0.1:28334
zmqpubrawblock=tcp://127.0.0.1:28335
rpcallowip=0.0.0.0/0
rpcport=$rpcPort
rpcuser=bitcorenodetest
rpcpassword=local321
uacomment=bitcore
EOF

	# register service
	cat >/lib/systemd/system/bitcoin.service <<EOF
[Unit]
Description=Bitcoin Core integration/staging tree
Documentation=https://github.com/bitcoin/bitcoin

[Service]
User=root
Group=root
Environment="OPTIONS=--testnet --rpcport=$rpcPort --rpcbind=0.0.0.0 -conf=$installPath/bitcoin.conf" 
ExecStart=$installPath/bin/bitcoind \$OPTIONS
StandardOutput=file:$installPath/logs/bitcoin.log
StandardError=file:$installPath/logs/error.log
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

	# start
	EXEC "systemctl daemon-reload && systemctl enable --now bitcoin"
	INFO "systemctl is-active bitcoin" && systemctl is-active bitcoin
}

function install_mongodb() {
	# environments
	local installPath="/data/mongodb"
	local version="4.0.25"
	local downloadUrl="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${version}.tgz"
	local port="27017"

	# check install path
	EXEC "rm -rf $installPath"
	EXEC "mkdir -p $installPath/{data,logs}"

	# download tarball
	EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

	# register path
	EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
	EXEC "ln -fs $installPath/bin/* /usr/bin/"
	EXEC "source /etc/profile"
	INFO "mongo --version" && mongo --version

	# config
	cat >$installPath/mongod.conf <<EOF
dbpath = $installPath/data/ #数据文件存放目录
logpath = $installPath/logs/mongodb.log #日志文件存放目录
port = $port  #端口
# fork = true  #以守护程序的方式启用，即在后台运行
bind_ip = 0.0.0.0    #允许所有的连接
EOF

	# register service
	cat >/lib/systemd/system/mongod.service <<EOF
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network-online.target
Wants=network-online.target

[Service]
User=root
Group=root
Environment="OPTIONS=-f $installPath/mongod.conf"
ExecStart=$installPath/bin/mongod \$OPTIONS
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2
StartLimitInterval=0
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false
# Recommended limits for mongod as specified in
# https://docs.mongodb.com/manual/reference/ulimit/#recommended-ulimit-settings

[Install]
WantedBy=multi-user.target
EOF

	# start
	EXEC "systemctl daemon-reload && systemctl enable --now mongod"
	INFO "systemctl status mongod" && systemctl status mongod
}

function install_node() {
	# environment
	local installPath="/data/node"
	local version="10.16.0"
	local downloadUrl="https://nodejs.org/download/release/v${version}/node-v${version}-linux-x64.tar.gz"

	# check install path
	EXEC "rm -rf $installPath"
	EXEC "mkdir -p $installPath"

	# download tarball
	EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

	# register path
	EXEC "sed -i '/node/d' /etc/profile"
	EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
	EXEC "ln -fs $installPath/bin/* /usr/bin/"
	EXEC "source /etc/profile"
	INFO "node -v" && node -v
	INFO "npm -v" && npm -v
}

function install_bitcore() {
	# environment
	local installPath="/data/BTC/bitcore"
	local version="8.25.12"
	local downloadUrl="https://github.com/bitpay/bitcore/archive/refs/tags/v${version}.tar.gz"
	local rpcPort="18332"
	local p2pPort="18333"
	local user="bitcore"

	# check bitcoin/mongodb/node/gcc/g++
	EXEC "bitcoin-cli -version"
	bitcoin-cli -version
	EXEC "systemctl is-active bitcoin"
	systemctl is-active bitcoin
	EXEC "mongo --version"
	mongo --version
	EXEC "systemctl is-active mongod"
	systemctl is-active mongod
	EXEC "node -v"
	node -v
	! hash gcc &>/dev/null && EXEC "apt update && apt install -y build-essential"
	EXEC "gcc --version"
	gcc --version
	EXEC "g++ --version"
	g++ --version
	! hash python &>/dev/null && EXEC "apt install -y python"
	EXEC "python --version"

	# check install path
	EXEC "rm -rf $installPath"
	EXEC "mkdir -p $installPath/logs"

	# check user
	! cat /etc/passwd | grep $user &>/dev/null && EXEC "useradd -m $user"

	# download tarball
	EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

	# chown
	EXEC "chown -R $user:$user $installPath"

	# compile and install
	INFO "su $user -c 'cd $installPath && npm install'"
	su $user -c "cd $installPath && npm install"

	# config
	cat >$installPath/bitcore.config.json <<EOF
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
            "username": "bitcore",
            "password": "local321"
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
	cat >$installPath/start.sh <<EOF
#!/usr/bin/env bash
export NODE_OPTIONS=--max_old_space_size=3145728
cd $installPath && npm run node &> $installPath/logs/$(date +%Y%m%d%H%M%S).log
EOF
	EXEC "chmod +x $installPath/start.sh"

	# chown
	EXEC "chown -R $user:$user $installPath"

	# register service
	cat >/lib/systemd/system/bitcore.service <<EOF
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

	# start
	EXEC "systemctl daemon-reload && systemctl enable --now bitcore"
	EXEC "systemctl status bitcore" && systemctl status bitcore
}

function main() {
	INFO "install bitcoin ..."
	systemctl is-active bitcoin &>/dev/null || install_bitcoin
	INFO "install_mongodb ..."
	systemctl is-active mongod &>/dev/null || install_mongodb
	INFO "install node ..."
	hash node &>/dev/null || install_node
	INFO "install bitcore ..."
	systemctl is-active bitcore &>/dev/null || install_bitcore
}

main
