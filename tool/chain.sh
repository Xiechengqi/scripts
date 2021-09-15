#!/usr/bin/env bash

#
# xiechengqi
# 2021/09/03
# get chain latest block number functions
#


# eth-node
## API: https://openethereum.github.io/JSONRPC
function get_eth_node_current_block_height() {
eth_node_url="http://$1"
blockNumber=`printf "%d\n" $(curl -s --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST $eth_node_url | grep -Po 'result[" :]+\K[^"]+')`
echo $blockNumber
}

# eth-index

# btc-node
## API: https://developer.bitcoin.org/reference/rpc/index.html
function get_btc_node_current_block_height() {
btc_node_url="$1"
blockNumber=`curl -s --user bitcoin --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }' -H 'content-type: text/plain;' $btc_node_url | awk -F ',"headers' '{print $1}' | awk -F ':' '{print $NF}'`
echo $blockNumber
}

# btc-index
## API: https://github.com/bitpay/bitcore/blob/master/packages/bitcore-node/docs/api-documentation.md
function get_btc_index_current_block_height() {
btc_index_url="$1"
blockNumber=`curl -SsL $btc_index_url/api/BTC/mainnet/block/tip | awk -F ',"merkleRoot' '{print $1}' | awk -F ':' '{print $NF}'`
echo $tmpBlockNumber | grep not &> /dev/null && blockNumber=`curl -SsL $btc_index_url/api/BTC/testnet/block/tip | awk -F ',"merkleRoot' '{print $1}' | awk -F ':' '{print $NF}'`
echo $blockNumber
}

# platon-node
## API: https://devdocs.platon.network/docs/zh-CN/Json_Rpc/
function get_platon_node_current_block_height() {
platon_node_url="$1"
blockNumber=`printf "%d\n" $(curl -s -H 'content-type: application/json' --data '{"jsonrpc":"2.0","method":"platon_blockNumber","params":[],"id":67}' -X POST $platon_node_url | grep -Po 'result[" :]+\K[^"]+')`
echo $blockNumber
}

# polkadot-node
## API: https://wiki.polkadot.network/docs/build-node-interaction#polkadot-rpc
function get_polkadot_node_current_block_height() {
polkadot_node_url="$1"
blockNumber=`printf "%d\n" $(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "chain_getBlock"}' $polkadot_node_url | jq .result.block.header.number | tr \" " ")`
echo $blockNumber
}

# conflux-node
## API: https://developer.confluxnetwork.org/conflux-doc/docs/json_rpc
function get_conflux_node_current_block_height() {
conflux_node_url="$1"
blockNumber=`printf "%d\n" $(curl -s --data '{"jsonrpc":"2.0","method":"cfx_epochNumber","params":["latest_mined"],"id":1}' -H "Content-Type: application/json" -X POST $conflux_node_url | grep -Po 'result[" :]+\K[^"]+')`
echo $blockNumber
}
