#!/usr/bin/env bash

#
# 2023/09/06
# xiechengqi
# fetch cosmos-like chain public rpc list
#

function fetch_rpc() {

local rpc="$1"

[ "$(curl -sIL --connect-timeout 2 -w "%{http_code}\n" -o /dev/null ${rpc})" != "200" ] && sed -i "/^${rpc}$/d" ${rpc_list} && return 1

echo "fetch_rpc ${rpc}"
timeout 5s curl -SsL ${rpc}/net_info | jq -jr '.result.peers[] | .node_info.other.rpc_address, " " + .remote_ip + "\n"' | awk -F ':' '{print $NF}' | awk '{print $NF,$1}' | tr ' ' ':' | sort | uniq | while read url
do

[ "$(curl -sIL --connect-timeout 2 -w "%{http_code}\n" -o /dev/null ${url})" == "200" ] && ! grep -E "^${url}$" ${rpc_list} &> /dev/null && echo ${url} >> ${rpc_list}

done

}

main() {

export public_rpc="${1}"
[ ".${public_rpc}" = "." ] && echo "Empty rpc endpoint, exit ..." && exit 1
export chain_id=$(curl -SsL ${public_rpc}/status | jq -r '.result.node_info.network')
export rpc_list="/tmp/${chain_id}_rpc.txt"
export rpc=${public_rpc}

fetch_rpc ${rpc}

while :
do

[ $(cat ${rpc_list} | wc -l) = "0" ] && exit 1
for rpc in $(tac ${rpc_list})
do
fetch_rpc ${rpc}
done

echo "sleep 1m ..." && sleep 1m
cat ${rpc_list}

done

}

main $@
