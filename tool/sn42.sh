#!/usr/bin/env bash

#
# sn42 common functions
# usage: source <(curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/refs/heads/master/tool/bench.sh)
#

# usage: sn42_tweets_number [axon]
function sn42_tweets_number_metric() {

axon=${1}
local teeUrl=$(curl -SsL http://${axon}/tee | sed 's/"//g')
[ ".${teeUrl}" = "." ] && echo "Error: ${axon}" && exit 1
local sig=$(curl -SsL -k ${teeUrl}/job/generate -H "Content-Type: application/json" -d '{ "type": "telemetry"}')
local uuid=$(curl -SsL -k ${teeUrl}/job/add -H "Content-Type: application/json" -d '{ "encrypted_job": "'${sig}'" }' | jq -r .uid)
local result=$(curl -SsL -k ${teeUrl}/job/status/${uuid})
local de=$(curl -SsL -k ${teeUrl}/job/result -H "Content-Type: application/json" -d '{ "encrypted_result": "'${result}'", "encrypted_request": "'${sig}'" }')
local tweets=$(echo ${de} | jq '.stats.twitter_returned_tweets')
echo "sn42_tweets_number{axon=\"${axon}\", tee=\"${teeUrl}\"} ${tweets}"

}
