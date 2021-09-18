#!/usr/bin/env bash

#
# xiechengqi
# 2021/09/15
# get chain latest block number functions
#


# eth-node
## API: https://openethereum.github.io/JSONRPC
function get_eth_node_current_block_height() {
local chain_type="eth-node"
chain_url="http://$1"
local chain_ip=`echo $1 | awk -F ':' '{print $1}'`
local chain_port=`echo $1 | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
local chain_current_block_height=`printf "%d\n" $(curl -s --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST $chain_url | grep -Po 'result[" :]+\K[^"]+')`

echo $chain_current_block_height
}

# eth-index
## API: https://github.com/Adamant-im/ETH-transactions-storage#make-indexers-api-public
function get_eth_index_current_block_height() {
local chain_type="eth-index"
chain_url="$1"
local chain_ip=`echo $1 | awk -F ':' '{print $1}'`
local chain_port=`echo $1 | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
local chain_current_block_height=`curl -SsL http://${chain_url}/max_block | awk -F ':' '{print $NF}' | awk -F '}' '{print $1}'`

echo $chain_current_block_height
}

# btc-node
## API: https://developer.bitcoin.org/reference/rpc/index.html
function get_btc_node_current_block_height() {
chain_type="btc-node"
chain_url="$1"
chain_ip=`echo $chain_url | awk -F ':' '{print $1}'`
chain_port=`echo $chain_url | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
rpcUser="$3"
rpcPassword="$4"
json_path="/tmp/$$_btc_node.json"
block_height_path="/tmp/$$_btc_node_block_height"
echo '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }' > $json_path
cmd="curl -s --user $rpcUser --data-binary @$json_path -H 'content-type: text/plain\;' $chain_url"
# echo $cmd
# echo $rpcPassword

expect << EOF > $block_height_path
spawn $cmd
expect "*"
send $rpcPassword\r
expect eof
EOF

chain_current_block_height=`cat $block_height_path | grep result | tail -1 | awk -F ',"headers' '{print $1}' | awk -F ':' '{print $NF}'`

echo $chain_current_block_height
}

# btc-index
## API: https://github.com/bitpay/bitcore/blob/master/packages/bitcore-node/docs/api-documentation.md
function get_btc_index_current_block_height() {
local chain_type="btc-index"
local chain_url="$1"
local chain_ip=`echo $1 | awk -F ':' '{print $1}'`
local chain_port=`echo $1 | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
local chain_current_block_height=`curl -SsL $chain_url/api/BTC/mainnet/block/tip | awk -F ',"merkleRoot' '{print $1}' | awk -F ':' '{print $NF}'`
echo $chain_current_block_height | grep not &> /dev/null && local chain_network="testnet" && local chain_current_block_height=`curl -SsL $chain_url/api/BTC/testnet/block/tip | awk -F ',"merkleRoot' '{print $1}' | awk -F ':' '{print $NF}'`

echo $chain_current_block_height
}

# platon-node
## API: https://devdocs.platon.network/docs/zh-CN/Json_Rpc/
function get_platon_node_current_block_height() {
local chain_type="platon-node"
local chain_url="$1"
local chain_ip=`echo $chain_url | awk -F ':' '{print $1}'`
local chain_port=`echo $chain_url | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
local chain_current_block_height=`printf "%d\n" $(curl -s -H 'content-type: application/json' --data '{"jsonrpc":"2.0","method":"platon_blockNumber","params":[],"id":67}' -X POST $chain_url | grep -Po 'result[" :]+\K[^"]+')`

echo $chain_current_block_height
}

# polkadot-node
## API: https://wiki.polkadot.network/docs/build-node-interaction#polkadot-rpc
function get_polkadot_node_current_block_height() {
local chain_type="polkadot-node"
local chain_url="$1"
local chain_ip=`echo $chain_url | awk -F ':' '{print $1}'`
local chain_port=`echo $chain_url | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
local chain_current_block_height=`printf "%d\n" $(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "chain_getBlock"}' $chain_url | jq .result.block.header.number | tr \" " ")`

echo $chain_current_block_height
}

# conflux-node
## API: https://developer.confluxnetwork.org/conflux-doc/docs/json_rpc
function get_conflux_node_current_block_height() {
local chain_type="conflux-node"
local chain_url="$1"
local chain_ip=`echo $chain_url | awk -F ':' '{print $1}'`
local chain_port=`echo $chain_url | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
local chain_current_block_height=`printf "%d\n" $(curl -s --data '{"jsonrpc":"2.0","method":"cfx_epochNumber","params":["latest_mined"],"id":1}' -H "Content-Type: application/json" -X POST $chain_url | grep -Po 'result[" :]+\K[^"]+')`

echo $chain_current_block_height
}

# chainx-node
## API: 
function get_chainx_node_current_block_height() {
local chain_type="chainx-node"
local chain_url="$1"
local chain_ip=`echo $chain_url | awk -F ':' '{print $1}'`
local chain_port=`echo $chain_url | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
local chain_current_block_height=`printf "%d\n" $(curl -X POST   -H "Content-Type: application/json"   --data '{"jsonrpc":"2.0","method":"chain_getHeader","params":[],"id":1}'   http://${chain_url} | jq .result.number | tr \" " ")`

echo $chain_current_block_height
}

# qtum-node
## API: https://docs.qtum.site/en/Qtum-RPC-API/
function get_qtum_node_current_block_height() {
chain_type="qtum-node"
chain_url="$1"
chain_ip=`echo $chain_url | awk -F ':' '{print $1}'`
chain_port=`echo $chain_url | awk -F ':' '{print $NF}'`
[ "$2" = "." ] && local chain_network="mainnet" || local chain_network="$2"
rpcUser="$3"
rpcPassword="$4"
json_path="/tmp/$$_qtum_node.json"
block_height_path="/tmp/$$_qtum_node_block_height"
echo '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }' > $json_path
cmd="curl -s --user $rpcUser --data-binary @$json_path -H 'content-type: text/plain\;' $chain_url"
# echo $cmd
# echo $rpcPassword

expect << EOF > $block_height_path
spawn $cmd
expect "*"
send $rpcPassword\r
expect eof
EOF

chain_current_block_height=`cat $block_height_path | grep result | tail -1 | awk -F ',"headers' '{print $1}' | awk -F ':' '{print $NF}'`

echo $chain_current_block_height
}

