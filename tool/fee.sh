#!/usr/bin/env bash

cid="$1"
curl -SsL -X POST -H "Content-Type application/json" --data '{"id":1,"jsonrpc":"2.0","params":["'${cid}'"],"method":"filscan.MessageDetails"}' 'https://api.filscan.io:8700/rpc/v1' | jq -r .result.all_gas_fee
