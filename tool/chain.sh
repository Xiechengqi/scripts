#!/usr/bin/env bash

#
# 2021/08/04
# xiechengqi
# 检查区块链全节点状态和基本信息
#

INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[32m %s \033[0m" "$1"
printf "\n"
}

INFOF() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[33m%s\033[0m" "$1"
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

function OK() {
echo -e "\033[32m [ok] \033[0m"
return 0
}

function FAIL() {
echo -e "\033[31m [fail] \033[0m"
return 1
}


function check_service() {
INFOF "check $serviceName ... "
systemctl is-active $serviceName &> /dev/null && OK || FAIL
}

function check_eth() {
EXEC "ps aux | grep -v grep | grep geth" && ps aux  | grep -v grep | grep geth
EXEC "ss -plunt | grep geth" && ss -plunt | grep geth
EXEC "geth attach http://127.0.0.1:8545 --exec 'eth.getBlock(0).hash'" && geth attach http://127.0.0.1:8545 --exec 'eth.getBlock(0).hash'
EXEC "geth attach http://127.0.0.1:8545 --exec 'eth.blockNumber'" && geth attach http://127.0.0.1:8545 --exec 'eth.blockNumber'
EXEC "geth attach http://127.0.0.1:8545 --exec 'eth.syncing'" && geth attach http://127.0.0.1:8545 --exec 'eth.syncing'
}

function check_btc() {
EXEC "ps aux | grep -v grep | grep bitcoind" && ps aux | grep -v grep | grep bitcoind
EXEC "ss -plunt | grep bitcoind" && ss -plunt | grep bitcoind
EXEC "bitcoin-cli -conf=/data/BTC/btc-node/conf/btc-node.conf -getinfo" && bitcoin-cli -conf=/data/BTC/btc-node/conf/btc-node.conf -getinfo
EXEC "bitcoin-cli -conf=/data/BTC/btc-node/conf/btc-node.conf getblockcount" && bitcoin-cli -conf=/data/BTC/btc-node/conf/btc-node.conf getblockcount
EXEC "bitcoin-cli -conf=/data/BTC/btc-node/conf/btc-node.conf getblockchaininfo" && bitcoin-cli -conf=/data/BTC/btc-node/conf/btc-node.conf getblockchaininfo
}

function check_platon() {
EXEC "ps axu | grep -v grep | grep platon" && ps axu | grep -v grep | grep platon
EXEC "ss -plunt | grep platon" && ss -plunt | grep platon
EXEC "platon attach http://127.0.0.1:6789 -exec 'platon.getBlock(0).hash'" && platon attach http://127.0.0.1:6789 -exec 'platon.getBlock(0).hash'
EXEC "platon attach http://127.0.0.1:6789 -exec 'platon.blockNumber'" && platon attach http://127.0.0.1:6789 -exec 'platon.blockNumber'
EXEC "platon attach http://127.0.0.1:6789 -exec 'platon.syncing'" && platon attach http://127.0.0.1:6789 -exec 'platon.syncing'
}

function check_polkadot() {
EXEC "ps axu | grep -v grep | grep polkadot" && ps axu | grep -v grep | grep polkadot
EXEC "ss -plunt | grep polkadot" && ss -plunt | grep polkadot
EXEC "curl -s -H \"Content-Type: application/json\" -d '{\"id\":1, \"jsonrpc\":\"2.0\", \"method\": \"chain_getBlock\"}' http://localhost:9933/ | grep number" && curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "chain_getBlock"}' http://localhost:9933/
}

function check_conflux() {
EXEC "ps aux | grep -v grep | grep conflux" && ps aux | grep -v grep | grep conflux
EXEC "ss -plunt | grep conflux" && ss -plunt | grep conflux

}

function check_iris() {
EXEC "ps aux | grep -v grep | grep iris" && ps aux | grep -v grep | grep iris
EXEC "ss -plunt | grep iris" && ss -plunt | grep iris
EXEC "iris status" && iris status
}

main() {

clear

if [ ".$1" = "." ]
then

local chainList=("eth" "btc" "platon" "polkadot" "conflux" "iris")
for nodeName in ${chainList[*]}
do
local serviceName="${nodeName}-node"
check_service $serviceName && check_${nodeName}
done  

else

while [ $# != 0 ]
do
local nodeName="$1"
local serviceName="$nodeName-node"
check_service $serviceName && check_${nodeName}
shift
done

fi

}

main $@
